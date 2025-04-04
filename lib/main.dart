import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baldomero Balatrez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
        useMaterial3: true,
      ),
      home: MenuInicio(),
    );
  }
}

class MenuInicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Baldomero Balatrez',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    )
                  ],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white, // Color del texto blanco
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Color del texto blanco
                  ),
                ),
                child: Text('Jugar'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  exit(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white, // Color del texto blanco
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Color del texto blanco
                  ),
                ),
                child: Text('Salir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Card> deck = [];
  List<Card> hand = [];
  int score = 0;
  int chips = 0;
  int multiplier = 2; 
  int round = 1;
  int handsRemaining = 4; 
  int discardsRemaining = 4; 
  bool gameOver = false;
  bool showDeckCount = false;
  int targetScore = 300; 
  int currentLevel = 1; 
  int maxCardsToChoose = 5; 
  bool showShop = false;

  @override
  void initState() {
    super.initState();
    _initializeDeck();
    _dealHand();
    targetScore = 300; 
  }

  void _initializeDeck() {
    final ranks = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A'
    ];
    final suits = ['♥', '♦', '♣', '♠'];

    deck.clear();
    for (var suit in suits) {
      for (var rank in ranks) {
        deck.add(Card(rank: rank, suit: suit));
      }
    }
    deck.shuffle();
  }

  void _dealHand() {
    setState(() {
      for (var card in hand) {
        card.isSelected = false;
      }

      hand.clear();
      if (deck.length < 8) {
        _initializeDeck();
      }
      for (int i = 0; i < 8; i++) {
        if (deck.isNotEmpty) {
          hand.add(deck.removeLast());
        } else {
          _initializeDeck();
          hand.add(deck.removeLast());
        }
      }
    });
  }

  void _playHand() {
    List<Card> playedCards = hand.where((card) => card.isSelected).toList();

    if (playedCards.length > maxCardsToChoose) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Selecciona un máximo de $maxCardsToChoose cartas'),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    if (playedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Selecciona cartas para jugar'),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    _evaluateHand(playedCards);

    setState(() {
      for (int i = hand.length - 1; i >= 0; i--) {
        if (hand[i].isSelected) {
          if (deck.isNotEmpty) {
            hand[i] = deck.removeLast();
          } else {
            _initializeDeck();
            hand[i] = deck.removeLast();
          }
          hand[i].isSelected = false;
        }
      }
      handsRemaining--;
    });

    if (handsRemaining <= 0) {
      _endRound();
    }
  }

  void _evaluateHand(List<Card> playedCards) {
    final ranks = playedCards.map((card) => card.rank).toList();
    final suits = playedCards.map((card) => card.suit).toList();
    bool isFlush = suits.toSet().length == 1;
    bool isStraight = _isStraight(ranks);
    int pairs = _countPairs(ranks);
    int threeOfAKind = _countOfAKind(ranks, 3);

    int handScore = 0;
    String handName = 'Carta alta';
    int baseMultiplier = multiplier;

    if (isStraight && isFlush && ranks.contains('A') && ranks.contains('K')) {
      handName = 'Escalera Real';
      handScore = 100;
      baseMultiplier = 10;
    } else if (isStraight && isFlush) {
      handName = 'Escalera de color';
      handScore = 100;
      baseMultiplier = 8;
    } else if (_countOfAKind(ranks, 4) == 1) {
      handName = 'Póker';
      handScore = 60;
      baseMultiplier = 7;
    } else if (_countOfAKind(ranks, 3) == 1 && pairs == 1) {
      handName = 'Full';
      handScore = 40;
      baseMultiplier = 4;
    } else if (isFlush) {
      handName = 'Color';
      handScore = 35;
      baseMultiplier = 4;
    } else if (isStraight) {
      handName = 'Escalera';
      handScore = 30;
      baseMultiplier = 4;
    } else if (threeOfAKind == 1) {
      handName = 'Trio';
      handScore = 30;
      baseMultiplier = 3;
    } else if (pairs == 2) {
      handName = 'Doble pareja';
      handScore = 20;
      baseMultiplier = 2;
    } else if (pairs == 1) {
      handName = 'Pareja';
      handScore = 10;
      baseMultiplier = 2;
    } else {
      handName = 'Carta alta';
      handScore = 5;
      baseMultiplier = 1;
    }

    setState(() {
      chips += handScore * baseMultiplier;
      score += handScore * baseMultiplier;

      
      if (handScore > 0 && score >= targetScore) {
        _levelUp();
      }
    });

    if (handScore > 0) {
      _showResultSnackBar(handName, handScore * baseMultiplier);
    } else {
      _showResultSnackBar(handName, 0); 
    }
  }

  void _discardAndReplace(List<int> indices) {
    List<int> selectedIndices = hand
        .asMap()
        .entries
        .where((entry) => entry.value.isSelected)
        .map((entry) => entry.key)
        .toList();
    if (selectedIndices.length > maxCardsToChoose) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Selecciona un máximo de $maxCardsToChoose cartas para descartar'),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    if (discardsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No te quedan descartes en esta ronda'),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() {
      indices.sort((a, b) => b.compareTo(a));
      for (var index in indices) {
        if (deck.isEmpty) _initializeDeck();
        hand.removeAt(index);
        hand.insert(index, deck.removeLast());
      }

      for (var card in hand) {
        card.isSelected = false;
      }

      discardsRemaining--;
    });
  }

  void _showResultSnackBar(String handName, int chips) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('¡$handName! +$chips fichas'),
              duration: Duration(seconds: 2)),
        );
      }
    });
  }

  void _endRound() {
    setState(() {
      round++;
      handsRemaining = 4;
      discardsRemaining = 4;

      if (round > 3) {
        gameOver = true;
      } else {
        _initializeDeck();
        _dealHand();
      }
    });
  }

  void _restartGame() {
    setState(() {
      score = 0;
      chips = 0;
      multiplier = 2;
      round = 1;
      handsRemaining = 4;
      discardsRemaining = 4;
      gameOver = false;
      currentLevel = 1;
      targetScore = 300; 
      maxCardsToChoose = 5;
      _initializeDeck();
      _dealHand();
    });
  }

  void _goToMainMenu() {
    Navigator.pop(context);
  }

  void _levelUp() {
    setState(() {
      currentLevel++;
      score = 0; 
      showShop = true;
      targetScore = 300 * currentLevel; 
      chips += 50; 
      multiplier =
          2 + currentLevel ~/ 2; 
    });
  }

 
  void _buyUpgrade(String upgrade) {
    setState(() {
      if (upgrade == 'maxCards+1' && chips >= 50) {
        maxCardsToChoose++;
        chips -= 50;
      } else if (upgrade == 'buyDiscard' && chips >= 30) {
        discardsRemaining++;
        chips -= 30;
      } else if (upgrade == 'buyWildCard' && chips >= 80) {
        
        chips -= 80;
        _addWildCardToDeck();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No tienes suficientes fichas para esta mejora'),
              duration: Duration(seconds: 2)),
        );
      }
      showShop = false; 
      _initializeDeck();
      _dealHand();
    });
  }

 
  void _addWildCardToDeck() {
    deck.add(Card(rank: 'Comodín', suit: ''));
  }

  bool _isStraight(List<String> ranks) {
    final rankOrder = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A'
    ];
    final indices = ranks.map((r) => rankOrder.indexOf(r)).toList()..sort();

    if (indices.contains(12) &&
        indices.contains(0) &&
        indices.contains(1) &&
        indices.contains(2) &&
        indices.contains(3)) {
      return true;
    }

    for (int i = 0; i < indices.length - 1; i++) {
      if (indices[i + 1] - indices[i] != 1) return false;
    }
    return true;
  }

  int _countPairs(List<String> ranks) {
    final rankCounts = <String, int>{};
    for (var rank in ranks) {
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }
    return rankCounts.values.where((count) => count == 2).length;
  }

  int _countOfAKind(List<String> ranks, int kind) {
    final rankCounts = <String, int>{};
    for (var rank in ranks) {
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }
    return rankCounts.values.where((count) => count == kind).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baldomero Balatrez', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: 'Reiniciar juego',
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              setState(() {
                showDeckCount = !showDeckCount;
              });
            },
            tooltip: 'Mostrar/Ocultar cartas restantes',
          ),
        ],
      ),
      body: showShop
          ? _buildShopScreen()
          : (gameOver ? _buildGameOverScreen() : _buildGameScreen()),
    );
  }

 
  Widget _buildShopScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('¡Felicidades! Nivel completado.',
              style: TextStyle(fontSize: 24)),
          Text('Bienvenido a la tienda', style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          Text('Fichas disponibles: $chips', style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: chips >= 50 ? () => _buyUpgrade('maxCards+1') : null,
            child: Text('Aumentar máximo de cartas a escoger (+1) - 50 fichas'),
          ),
          ElevatedButton(
            onPressed: chips >= 30 ? () => _buyUpgrade('buyDiscard') : null,
            child: Text('Comprar un descarte adicional - 30 fichas'),
          ),
          ElevatedButton(
            onPressed: chips >= 80 ? () => _buyUpgrade('buyWildCard') : null,
            child: Text('Comprar un comodín - 80 fichas'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                showShop = false; 
                _initializeDeck();
                _dealHand();
              });
            },
            child: Text('Volver al juego'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Nivel', style: TextStyle(fontSize: 16)),
                      Text('$currentLevel',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Puntuación', style: TextStyle(fontSize: 16)),
                      Text('$score',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Fichas', style: TextStyle(fontSize: 16)),
                      Text('$chips',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Objetivo: $targetScore fichas',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Manos', style: TextStyle(fontSize: 16)),
                      Text('$handsRemaining',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Descartes', style: TextStyle(fontSize: 16)),
                      Text('$discardsRemaining',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Multiplicador', style: TextStyle(fontSize: 16)),
                      Text('x$multiplier',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              if (showDeckCount)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Cartas restantes: ${deck.length} - ${deck.map((card) => '${card.rank} ${card.suit}').join(', ')}',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(hand.length, (index) {
                return CardWidget(
                  card: hand[index],
                  isSelected: hand[index].isSelected,
                  onTap: () {
                    int selectedCount = hand
                        .where((card) => card.isSelected)
                        .length; 
                    setState(() {
                      if (hand[index].rank != 'Comodín') {
                        if (!hand[index].isSelected &&
                            selectedCount < maxCardsToChoose) {
                          hand[index].isSelected = !hand[index].isSelected;
                        } else if (hand[index].isSelected) {
                          hand[index].isSelected = !hand[index].isSelected;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'No puedes seleccionar más de $maxCardsToChoose cartas'),
                                duration: Duration(seconds: 1)),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('No puedes seleccionar comodines'),
                              duration: Duration(seconds: 1)),
                        );
                      }
                    });
                  },
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _playHand,
                child: Text('Jugar Mano'),
              ),
              ElevatedButton(
                onPressed: () {
                  List<int> selectedIndices = hand
                      .asMap()
                      .entries
                      .where((entry) => entry.value.isSelected)
                      .map((entry) => entry.key)
                      .toList();
                  _discardAndReplace(selectedIndices);
                },
                child: Text('Descartar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('¡Juego Terminado!', style: TextStyle(fontSize: 32)),
          SizedBox(height: 20),
          Text('Puntuación Final: $score', style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _restartGame,
            child: Text('Reiniciar Juego'),
          ),
          ElevatedButton(
            onPressed: _goToMainMenu,
            child: Text('Volver al Menú'),
          ),
        ],
      ),
    );
  }
}

class Card {
  String rank;
  String suit;
  bool isSelected;

  Card({required this.rank, required this.suit, this.isSelected = false});
}

class CardWidget extends StatelessWidget {
  final Card card;
  final bool isSelected;
  final VoidCallback onTap;

  CardWidget(
      {required this.card, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[200] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
        ),
        child: Text(
          '${card.rank} ${card.suit}',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
