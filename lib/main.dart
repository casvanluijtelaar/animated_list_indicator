import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AnimatedListSelector(
            children: const [
              AnimatedListItem(title: '💙Label can be arbitrary'),
              AnimatedListItem(title: 'Short'),
              AnimatedListItem(title: 'Or incredibly looooooooooobg'),
              AnimatedListItem(title: 'Another label'),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedListSelector extends StatefulWidget {
  AnimatedListSelector({
    Key? key,
    required this.children,
  })  : assert(children.isNotEmpty),
        super(key: key);

  final List<AnimatedListItem> children;

  @override
  _AnimatedListSelectorState createState() => _AnimatedListSelectorState();
}

class _AnimatedListSelectorState extends State<AnimatedListSelector> {
  Duration _duration = const Duration(milliseconds: 150);

  late ScrollController _controller;
  late List<GlobalKey> _keys;

  bool _isAnimating = false;

  double _currentWidth = 0;
  double _currentOffset = 0;

  double _prevScrollPosition = 0;

  /// when an item is tapped we need to animate the list to the correct item
  /// and animate the indicator beneath that item
  void onItemTapped(int index) async {
    /// set the animation duration to the animating length
    setState(() {
      _duration = const Duration(milliseconds: 150);
      _isAnimating = true;
    });

    /// to prevend scroll interuptions wait for the list scroll to finish before
    /// continuing
    await _controller.animateTo(
      _getItemOffset(index),
      duration: _duration,
      curve: Curves.easeOut,
    );

    /// calculate the width the indicator is supposed to fill
    final context = _keys[index].currentContext!;
    final width = context.size!.width;

    /// calculate the indicator offset
    final renderbox = context.findRenderObject()! as RenderBox;
    final offset = renderbox.localToGlobal(Offset.zero);

    /// rebuild so animated widgets can do their animations
    setState(() {
      _isAnimating = false;
      _currentWidth = width;
      _currentOffset = offset.dx;
    });
  }

  /// to calculate the list space offset of an item we add the width of all
  /// the items proceeding it.
  double _getItemOffset(int index) {
    double x = 0;
    for (var i = 0; i < index; i++) {
      x += _keys[index].currentContext!.size!.width;
    }
    return x;
  }

  /// when scrolling we ant to fix the indicator to the item position,
  /// so we need update the indicator position without delay
  void _onScroll() {
    setState(() {
      // we don't want to interupt the scroll animation
      if (!_isAnimating) _duration = const Duration(microseconds: 1);
      _currentOffset += _prevScrollPosition - _controller.offset;
      _prevScrollPosition = _controller.offset;
    });
  }

  @override
  void initState() {
    super.initState();

    /// generate a list of globalKeys to assign to the list items so we can
    /// reference their context
    _keys = List.generate(widget.children.length, (_) => GlobalKey());

    _controller = ScrollController();
    _controller.addListener(_onScroll);

    /// update the initial indicator state after the three has been rendered
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _currentWidth = _keys[0].currentContext!.size!.width;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            children: widget.children.map((item) {
              final index = widget.children.indexOf(item);

              return GestureDetector(
                key: _keys[index],
                onTap: () => onItemTapped(index),
                child: item,
              );
            }).toList(),
          ),
          AnimatedPositioned(
            duration: _duration,
            left: _currentOffset,
            bottom: 0,
            child: AnimatedContainer(
              duration: _duration,
              height: 20,
              width: _currentWidth,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(102, 88, 245, 1),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(188, 201, 211, 1)),
        color: const Color.fromRGBO(195, 208, 217, 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(child: Text(title)),
    );
  }
}
