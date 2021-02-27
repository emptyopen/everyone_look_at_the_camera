import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class WrapToggleTextButtons extends StatefulWidget {
  final List<String> textList;
  final List<bool> isSelected;
  final Function onPressed;
  final double boxWidth;
  final double boxHeight;

  WrapToggleTextButtons({
    @required this.textList,
    @required this.isSelected,
    @required this.onPressed,
    this.boxWidth,
    this.boxHeight,
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
          text: index == 0 ? text : '"$text"',
          width: widget.boxWidth,
          height: widget.boxHeight,
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
  final double height;
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
          color: active ? Theme.of(context).accentColor : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
      child: InkWell(
        child: Center(
          child: AutoSizeText(
            text,
            maxLines: 1,
            style: TextStyle(
              color: index == 0
                  ? Colors.grey
                  : active
                      ? Colors.black
                      : Theme.of(context).disabledColor,
            ),
          ),
        ),
        onTap: () => onTap(index),
      ),
    );
  }
}
