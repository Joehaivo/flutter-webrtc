import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_example/src/widgets/kyy/Cmd.dart';
import 'package:flutter_webrtc_example/src/widgets/kyy/DataChannel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class Kyy extends StatefulWidget {
  @override
  State<Kyy> createState() => _KyyState();
}

class _KyyState extends State<Kyy> {
  final EVENT_RTC_MESSAGE = 'rtcmessage';
  final _remoteRenderer = RTCVideoRenderer();
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              _dataChannel?.send(RTCDataChannelMessage(jsonEncode(MouseMsg(type: 3, data: null))));
            },
          ),
          IconButton(
            icon: Icon(Icons.play_circle),
            onPressed: _play,
          )
        ],
      ),
      body: Container(
        color: Colors.greenAccent,
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 9/16,
          child: LayoutBuilder(builder: (context, constraints) {
            return GestureDetector(
                onPanDown: (detail) {
                  print("onPanDown: ${detail.globalPosition}, ${detail.localPosition}");
                  var mouseData = MouseData(
                      ActiveType: 1,
                      x: detail.localPosition.dx,
                      y: detail.localPosition.dy,
                      InterfaceWidth: constraints.biggest.width.toInt(),
                      InterfaceHigh: constraints.biggest.height.toInt());
                  var mouseMsg = MouseMsg(type: 0, data: mouseData);
                  _dataChannel?.send(RTCDataChannelMessage(jsonEncode(mouseMsg)));
                },
                onPanStart: (detail) {
                  print("onPanStart: ${detail.kind}, ${detail.globalPosition}, ${detail.localPosition}");
                  var mouseData = MouseData(
                      ActiveType: 1,
                      x: detail.localPosition.dx,
                      y: detail.localPosition.dy,
                      InterfaceWidth: constraints.biggest.width.toInt(),
                      InterfaceHigh: constraints.biggest.height.toInt());
                  var mouseMsg = MouseMsg(type: 0, data: mouseData);
                  // _dataChannel?.send(RTCDataChannelMessage(jsonEncode(mouseMsg)));
                },
                onPanUpdate: (detail) {
                  print("onPanUpdate: ${detail.globalPosition}, ${detail.localPosition}");
                  var mouseData = MouseData(
                      ActiveType: 2,
                      x: detail.localPosition.dx,
                      y: detail.localPosition.dy,
                      InterfaceWidth: constraints.biggest.width.toInt(),
                      InterfaceHigh: constraints.biggest.height.toInt());
                  var mouseMsg = MouseMsg(type: 0, data: mouseData);
                  _dataChannel?.send(RTCDataChannelMessage(jsonEncode(mouseMsg)));
                },
                onPanEnd: (detail) {
                  print("onPanEnd: ${detail.velocity}, ${detail.primaryVelocity}, ${detail}");
                  var mouseData = MouseData(
                      ActiveType: 3,
                      x: 0,
                      y: 0,
                      InterfaceWidth: constraints.biggest.width.toInt(),
                      InterfaceHigh: constraints.biggest.height.toInt());
                  var mouseMsg = MouseMsg(type: 0, data: mouseData);
                  _dataChannel?.send(RTCDataChannelMessage(jsonEncode(mouseMsg)));
                },
                onPanCancel: () {
                  print("onPanCancel: ");
                  var mouseData = MouseData(
                      ActiveType: 3,
                      x: 0,
                      y: 0,
                      InterfaceWidth: constraints.biggest.width.toInt(),
                      InterfaceHigh: constraints.biggest.height.toInt());
                  var mouseMsg = MouseMsg(type: 0, data: mouseData);
                  _dataChannel?.send(RTCDataChannelMessage(jsonEncode(mouseMsg)));
                },
                child: RTCVideoView(_remoteRenderer));
          }),
        ),
      ),
    );
  }

  Future<void> _play() async {
    await _remoteRenderer.initialize();
    _socket = IO.io(
        'https://testsign.kyyai.com/signaling',
        OptionBuilder().setTransports(['websocket']).setQuery({
          'auth': 'vmos_178_KCiD1ZFscKnErVOcS7ESscn37wrzDieb',
          'room': 'f4a0cd2b-b680-472c-b93e-13c673683ec6'
        }).build());

    _socket?.onConnect((data) {
      print('onConnect: $data');
      initRemotePeerConnection();
    });
    _socket?.onConnecting((data) => {print('onConnecting: $data')});
    _socket?.onConnectError((data) => print('onConnectError: $data'));
    _socket?.onError((data) => print('onError: $data'));
    _socket?.onDisconnect((data) => print('onDisconnect: $data'));
    _socket?.on(EVENT_RTC_MESSAGE, (rtcMsg) {
      print('on rtcmessage: $rtcMsg');
      var msg = jsonDecode(rtcMsg);
      var cmd = msg['cmd'];
      if (cmd == 'candidate') {
        var data = jsonDecode(msg['data']);
        _peerConnection?.addCandidate(RTCIceCandidate(data['candidate'], data['id'], data['label']));
      } else if (cmd == 'answer') {
        var data = jsonDecode(msg['data']);
        _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], cmd));
      }
    });
    _socket?.connect();
  }

  Future<void> initRemotePeerConnection() async {
    final _configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': 'turn:202.104.173.101:3478',
          'username': '1705048502:heyxiaogui',
          'credential': 'OQkqrxh8UNVl3TlzGgwZmbnKLTo='
        },
      ]
    };
    _peerConnection = await createPeerConnection(_configuration);
    print('_peerConnection: ${_peerConnection}');

    _peerConnection?.onTrack = (event) {
      print('onTrack ${event.track.id}');

      if (event.track.kind == 'video') {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _peerConnection?.onSignalingState = (state) async {
      print('_peerConnection: onSignalingState($state)');
      if (state == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        // await _createLocalOffer();
      }
    };

    _peerConnection?.onIceGatheringState = (state) async {
      print('_peerConnection: onIceGatheringState($state)');
    };
    _peerConnection?.onIceConnectionState = (state) async {
      print('_peerConnection: onIceConnectionState($state)');
    };
    _peerConnection?.onConnectionState = (state) async {
      print('_peerConnection: onConnectionState($state)');
    };

    _peerConnection?.onIceCandidate = (ice) async {
      print('_peerConnection: onIceCandidate: ${ice.candidate}');
      var candidate2 =
          Candidate(id: ice.sdpMid!, label: ice.sdpMLineIndex!, candidate: ice.candidate!, type: 'candidate');
      var cmd = Cmd(cmd: 'candidate', data: candidate2);
      sendSignaling(jsonEncode(cmd));
    };
    _peerConnection?.onRenegotiationNeeded = () async {
      print('_peerConnection: RemoteRenegotiationNeeded');
      await _createLocalOffer();
    };
    _peerConnection?.onAddTrack = (stream, state) {
      print('onAddTrack: $stream, $state');
    };
    await _createDataChannel();
  }

  Future<void> _createLocalOffer() async {
    var rtcSessionDescription = await _peerConnection?.createOffer({
      'mandatory': {
        'OfferToReceiveVideo': true,
      }
    });
    if (rtcSessionDescription != null) {
      await _peerConnection?.setLocalDescription(rtcSessionDescription);
      var data = Sdp(sdp: rtcSessionDescription.sdp!, type: 'offer');
      var cmd = Cmd(cmd: 'offer', data: data);
      sendSignaling(jsonEncode(cmd));
    }
  }

  void sendSignaling(dynamic data) {
    print('sendSignaling: $data');
    _socket?.emit(EVENT_RTC_MESSAGE, data);
  }

  Future<void> _createDataChannel() async {
    _dataChannel = await _peerConnection?.createDataChannel('fileTransfer', RTCDataChannelInit());
    _dataChannel?.onDataChannelState = (state) {
      print('onDataChannelState $state');
    };

    _dataChannel?.onMessage = (data) {
      print('onMessage: $data');
    };
  }
}
