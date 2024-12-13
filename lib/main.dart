import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<UsbDevice> usbDevices = [];
  UsbDevice? portaSelecionada;
  UsbPort? porta;
  bool? aberta;
  bool iniciou = false;
  String leitura = '';
  double peso = 0.00;

  Future<void> listarPortas () async {
    List<UsbDevice> lista = await UsbSerial.listDevices();
    usbDevices = lista.where((i) => i.productName != null).toList();
    setState(() {

    });
  }

  Future<void> selecionarPorta(UsbDevice usb) async {
    portaSelecionada = usb;
    try{
      porta = await portaSelecionada?.create();

      await porta!.setPortParameters(2400, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      aberta = await porta?.open();

      if(aberta ?? false){
        porta?.inputStream?.listen((Uint8List event) async{
          onUsbEvent(event); //process the incoming event here...
        });
      }
    }catch (e){
      //handle Error
    }
    setState(() {

    });
  }

  Future<void> lerPeso() async {
    try{
      String data = String.fromCharCode(5) + String.fromCharCode(13);
      await porta!.write(Uint8List.fromList(data.codeUnits));
    }catch (e){
      //handle Error
    }
    setState(() {

    });
  }

  void onUsbEvent(Uint8List event){
    if(event.isEmpty) return;
    if (event[0] == 2) {
      leitura = '';
      iniciou = true;
    }
    if (iniciou) {
      if (event[0] != 2 && event[0] != 3) {
        leitura += utf8.decode(event);
      }
    }
    if (event[0] == 3) {
      peso = double.parse(leitura);
      if (peso > 0) {
        peso = peso / 1000;
      }
      iniciou = false;
      setState(() {

      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listarPortas();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Porta selecionada: ${portaSelecionada?.productName ?? ''}'),
        ),
        body: ListView.builder(
            itemCount: usbDevices.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('${usbDevices[index].productName} - ${usbDevices[index].manufacturerName}'),
                trailing: ElevatedButton.icon(label: const Text('Selecionar'), onPressed: () => {
                  selecionarPorta(usbDevices[index])
                }, icon: const Icon(Icons.done)),
              );
            }
        ),
        bottomSheet: Row(
          children: [
            ElevatedButton.icon(label: const Text('Ler Peso'), onPressed: porta != null? lerPeso: null, icon: const Icon(Icons.send)),
            const SizedBox(width: 100,),
            Text('${peso.toStringAsFixed(3).replaceAll('.', ',')} kg', style: const TextStyle(fontSize: 36),),
          ],
        )
      ),
    );
  }
}  