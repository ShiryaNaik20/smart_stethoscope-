import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

typedef VoidCallback = void Function();

class WebSocketService {
  WebSocket? _socket;
  bool _connected = false;

  Function(List<double>)? onWaveformData;
  Function(List<int>)? onRawSamples;
  Function(String)? onConnectionError;
  VoidCallback? onConnected;

  bool get isConnected => _connected;

  Future<void> connect(String ip) async {
    try {
      print('[WS] Connecting to ws://$ip:81');
      _socket = await WebSocket.connect('ws://$ip:81')
          .timeout(const Duration(seconds: 8));
      _connected = true;
      print('[WS] Connected!');
      onConnected?.call();

      _socket!.listen(
        (data) {
          try {
            Uint8List bytes;
            if (data is Uint8List) {
              bytes = data;
            } else if (data is List<int>) {
              bytes = Uint8List.fromList(data);
            } else {
              return;
            }

            if (bytes.length < 2) return;

            final int16View = bytes.buffer.asInt16List(
              bytes.offsetInBytes,
              bytes.lengthInBytes ~/ 2,
            );

            // Send raw int16 as doubles — NOT divided by 32768
            // Painter needs real amplitude values to auto-scale
            final rawAsDouble =
                int16View.map((s) => s.toDouble()).toList();

            onWaveformData?.call(rawAsDouble);
            onRawSamples?.call(int16View.toList());
          } catch (e) {
            print('[WS] Handler error: $e');
          }
        },
        onError: (e) {
          print('[WS] Error: $e');
          _connected = false;
          onConnectionError?.call(e.toString());
        },
        onDone: () {
          print('[WS] Closed');
          _connected = false;
          onConnectionError
              ?.call('ESP32 disconnected (${_socket?.closeCode})');
        },
        cancelOnError: false,
      );
    } on SocketException catch (e) {
      _connected = false;
      onConnectionError
          ?.call('Cannot reach ESP32 at $ip:81\n${e.message}');
    } on TimeoutException catch (_) {
      _connected = false;
      onConnectionError
          ?.call('Timeout — ESP32 not responding at $ip:81');
    } catch (e) {
      _connected = false;
      onConnectionError?.call(e.toString());
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    _connected = false;
  }
}