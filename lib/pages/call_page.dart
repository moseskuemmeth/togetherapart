import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final AgoraClient _client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
          appId: '7dd1a83ab91e4e3ebc5910697db35d02',
          channelName: 'firstchannel',
          tempToken:'007eJxTYBBl0r8TwrXs2PcpDRO1bXjD87fX363ZuN8kmH1vavjH0M0KDOYpKYaJFsaJSZaGqSapxqlJyaaWhgZmluYpScamKQZGnWfb0xoCGRnSTdayMjJAIIjPw5CWWVRckpyRmJeXmsPAAAAUcSI0'));

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await _client.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        automaticallyImplyLeading: false,
      ),
      body: PopScope(child: SafeArea(
        child: Stack(
          children: [
            AgoraVideoViewer(
              client: _client,
              layoutType: Layout.floating,
              showNumberOfUsers: true,
            ),
            AgoraVideoButtons(
              client: _client,
              enabledButtons: const [
                BuiltInButtons.toggleCamera,
                BuiltInButtons.callEnd,
                BuiltInButtons.toggleMic
              ],
            ),
          ],
        ),
      ), 
      onPopInvoked: (value)  => true
      )
    );
  }
}
