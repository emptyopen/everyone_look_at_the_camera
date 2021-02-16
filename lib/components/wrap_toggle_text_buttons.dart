import 'package:flutter/material.dart';

class WrapToggleTextButtons extends StatefulWidget {
  final List<String> textList;
  final List<bool> isSelected;
  final Function onPressed;
  final double boxWidth;

  WrapToggleTextButtons({
    @required this.textList,
    @required this.isSelected,
    @required this.onPressed,
    this.boxWidth,
  });

  @override
  _WrapToggleTextButtonsState createState() => _WrapToggleTextButtonsState();
}

class _WrapToggleTextButtonsState extends State<WrapToggleTextButtons> {
  int index;

  @override
  Widget build(BuildContext context) {
    assert(widget.textList.length == widget.isSelected.length);
    index = -1;
    return Wrap(
      children: widget.textList.map((String text) {
        index++;
        return TextToggleButton(
          active: widget.isSelected[index],
          text: text,
          width: widget.boxWidth,
          onTap: widget.onPressed,
          index: index,
        );
      }).toList(),
    );
  }
}

class TextToggleButton extends StatelessWidget {
  final bool active;
  final String text;
  final Function onTap;
  final double width;
  final int height;
  final int index;

  TextToggleButton({
    @required this.active,
    @required this.text,
    @required this.onTap,
    @required this.index,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 70,
      height: height ?? 30,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: InkWell(
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active
                  ? Theme.of(context).accentColor
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
        onTap: () => onTap(index),
      ),
    );
  }
}
