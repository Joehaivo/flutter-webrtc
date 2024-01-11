import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class Kyy extends StatefulWidget {
  @override
  State<Kyy> createState() => _KyyState();
}

class _KyyState extends State<Kyy> {
  final EVENT_RTC_MESSAGE = 'rtcmessage';
  final _remoteRenderer = RTCVideoRenderer();
  IO.Socket? socket;
  RTCPeerConnection? _remotePeerConnection;

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
            icon: Icon(Icons.play_circle),
            onPressed: _play,
          )
        ],
      ),
      body: RTCVideoView(_remoteRenderer),
    );
  }

  Future<void> _play() async {
    await _remoteRenderer.initialize();
    socket = IO.io(
        'https://testsign.kyyai.com/signaling',
        OptionBuilder().setTransports(['websocket']).setQuery({
          'auth': 'vmos_178_KCiD1ZFscKnErVOcS7ESscn37wrzDieb',
          'room': 'f4a0cd2b-b680-472c-b93e-13c673683ec6'
        }).build());

    socket?.onConnect((data) {
      print('onConnect: $data');
      initRemotePeerConnection();
    });
    socket?.onConnecting((data) => {print('onConnecting: $data')});
    socket?.onConnectError((data) => print('onConnectError: $data'));
    socket?.onError((data) => print('onError: $data'));
    socket?.onDisconnect((data) => print('onDisconnect: $data'));
    socket?.on(EVENT_RTC_MESSAGE, (data) => {print('on rtcmessage: $data')});
    socket?.connect();
  }

  Future<void> initRemotePeerConnection() async {
    try {
      final _configuration = <String, dynamic>{
        'iceServers': [
          {
            'urls': 'turn:202.104.173.101:3478',
            'username': '1705048502:heyxiaogui',
            'credential': 'OQkqrxh8UNVl3TlzGgwZmbnKLTo='
          },
        ]
      };
      _remotePeerConnection = await createPeerConnection(_configuration);
      print('_remotePeerConnection: ${_remotePeerConnection}');

      _remotePeerConnection?.onTrack = _onTrack;

      _remotePeerConnection?.onSignalingState = (state) async {
        var state2 = await _remotePeerConnection?.getSignalingState();
        print('remote pc: onSignalingState($state), state2($state2)');
        await _createLocalOffer();
      };

      _remotePeerConnection?.onIceGatheringState = (state) async {
        var state2 = await _remotePeerConnection?.getIceGatheringState();
        print('remote pc: onIceGatheringState($state), state2($state2)');
      };
      _remotePeerConnection?.onIceConnectionState = (state) async {
        var state2 = await _remotePeerConnection?.getIceConnectionState();
        print('remote pc: onIceConnectionState($state), state2($state2)');
      };
      _remotePeerConnection?.onConnectionState = (state) async {
        var state2 = await _remotePeerConnection?.getConnectionState();
        print('remote pc: onConnectionState($state), state2($state2)');
      };

      _remotePeerConnection?.onIceCandidate = _onRemoteCandidate;
      _remotePeerConnection?.onRenegotiationNeeded =
          _onRemoteRenegotiationNeeded;
      _remotePeerConnection?.onAddTrack = (stream, state) {
        print('onAddTrack: $stream, $state');
      };
      await _createDataChannel();
      await _createLocalOffer();
    } catch (e) {
      print("initRemotePC: " + e.toString());
    }
  }

  Future<void> _createLocalOffer() async {
    final oaConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': true,
      }
    };
    var rtcSessionDescription =
        await _remotePeerConnection?.createOffer(oaConstraints);
    if (rtcSessionDescription != null) {
      await _remotePeerConnection?.setLocalDescription(rtcSessionDescription);
      socket?.emit(EVENT_RTC_MESSAGE, {
        'cmd': 'offer',
        'data': {'sdp': rtcSessionDescription.sdp, 'type': 'offer'}
      });
    }
  }

  void _onTrack(RTCTrackEvent event) async {
    print('onTrack ${event.track.id}');

    if (event.track.kind == 'video') {
      setState(() {
        _remoteRenderer.srcObject = event.streams[0];
      });
    }
  }

  void _onRemoteCandidate(RTCIceCandidate remoteCandidate) async {
    print('onRemoteCandidate: ${remoteCandidate.candidate}');
    try {
      var candidate = RTCIceCandidate(
        remoteCandidate.candidate!,
        remoteCandidate.sdpMid!,
        remoteCandidate.sdpMLineIndex!,
      );
      // await _localPeerConnection!.addCandidate(candidate);
    } catch (e) {
      print(
          'Unable to add candidate ${remoteCandidate.candidate} to local connection');
    }
  }

  void _onRemoteRenegotiationNeeded() {
    print('RemoteRenegotiationNeeded');
  }

  Future<void> _createDataChannel() async {
    var rtcDataChannel = await _remotePeerConnection?.createDataChannel(
        'fileTransfer', RTCDataChannelInit()..id = 1);
    rtcDataChannel?.onDataChannelState = (state) {
      print('onDataChannelState $state');
    };

    rtcDataChannel!.onMessage = (data) {
      print('onMessage: $data');
    };
  }
}
