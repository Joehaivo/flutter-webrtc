class Cmd {
  Cmd({
    required this.cmd,
    required this.data,
  });

  String cmd;
  dynamic data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['cmd'] = cmd;
    map['data'] = data;
    return map;
  }
}

class Sdp {
  Sdp({
    required this.type,
    required this.sdp,
  });

  String type;
  String sdp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['sdp'] = sdp;
    return map;
  }
}

class Candidate {
  Candidate({
    required this.id,
    required this.label,
    required this.candidate,
    required this.type,
  });

  String id;
  int label;
  String candidate;
  String type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['label'] = label;
    map['candidate'] = candidate;
    map['type'] = type;
    return map;
  }
}
