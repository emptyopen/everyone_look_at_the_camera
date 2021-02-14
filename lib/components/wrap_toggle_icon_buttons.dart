import 'package:flutter/material.dart';

class WrapToggleIconButtons extends StatefulWidget {
  final List<IconData> iconList;
  final List<bool> isSelected;
  final Function onPressed;

  WrapToggleIconButtons({
    @required this.iconList,
    @required this.isSelected,
    @required this.onPressed,
  });

  @override
  _WrapToggleIconButtonsState createState() => _WrapToggleIconButtonsState();
}

class _WrapToggleIconButtonsState extends State<WrapToggleIconButtons> {
  int index;

  @override
  Widget build(BuildContext context) {
    assert(widget.iconList.length == widget.isSelected.length);
    index = -1;
    return Wrap(
      children: widget.iconList.map((IconData icon) {
        index++;
        return IconToggleButton(
          active: widget.isSelected[index],
          icon: icon,
          onTap: widget.onPressed,
          index: index,
        );
      }).toList(),
    );
  }
}

class IconToggleButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final Function onTap;
  final int width;
  final int height;
  final int index;

  IconToggleButton({
    @required this.active,
    @required this.icon,
    @required this.onTap,
    @required this.index,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 60,
      height: height ?? 60,
      child: InkWell(
        child: Icon(
          icon,
          color: active
              ? Theme.of(context).accentColor
              : Theme.of(context).disabledColor,
        ),
        onTap: () => onTap(index),
      ),
    );
  }
}
