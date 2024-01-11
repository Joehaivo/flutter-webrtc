class MouseMsg {

  MouseMsg({required this.type, required this.data});
  int type;

  MouseData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['data'] = data;
    return map;
  }
}

class MouseData {

  MouseData({required this.ActiveType, required this.x, required this.y, required this.InterfaceWidth, required this.InterfaceHigh});
  int ActiveType;

  double x;

  double y;

  int InterfaceWidth;

  int InterfaceHigh;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ActiveType'] = ActiveType;
    map['x'] = x;
    map['y'] = y;
    map['InterfaceWidth'] = InterfaceWidth;
    map['InterfaceHigh'] = InterfaceHigh;
    return map;
  }
}
