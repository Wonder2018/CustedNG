import 'package:flutter/material.dart';

class SettingItem extends StatelessWidget {
  const SettingItem({
    Key key,
    @required this.title,
    this.onTap,
    this.content = "",
    this.rightBtn,
    this.textAlign = TextAlign.start,
    this.titleStyle,
    this.contentStyle,
    this.height,
    this.isShowArrow = true,
    this.icon,
  }): super(key: key);

  final GestureTapCallback onTap;
  final String title;
  final String content;
  final TextAlign textAlign;
  final TextStyle titleStyle;
  final TextStyle contentStyle;
  final Widget rightBtn;
  final double height;
  final bool isShowArrow;//是否显示右侧箭头
  final Icon icon;//左侧图片名字 不传则不显示图片
  @override
  Widget build(BuildContext context) {

    return Container(
        height: this.height ?? 55.0,
        margin: EdgeInsets.only(left: 16, right: 16),
        width: double.infinity,
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
          clipBehavior: Clip.antiAlias,
          semanticContainer: false,
          child: InkWell(
              onTap: this.onTap,
              child: Stack(
                children: [
                  Row(
                    children: <Widget>[
                      SizedBox(width: 10.0),
                      this.icon ?? Container(),
                      SizedBox(width: 10.0),
                      Text(this.title,
                          style: this.titleStyle ??
                              new TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 14.0,
                              )),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: 16, right: 16),
                          child: Text(this.content,
                              textAlign: this.textAlign,
                              overflow: TextOverflow.ellipsis,
                              style: this.contentStyle ??
                                  new TextStyle(
                                    fontSize: 14.0,
                                    color: Color(0xFFCCCCCC),
                                  )),
                        ),
                      ),
                      this.isShowArrow
                          ? Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            )
                          : Container(),
                      SizedBox(width: 10.0),
                    ],
                  ),
                  this.rightBtn ?? Container()
                ],
              )),
        )
    );
  }
}