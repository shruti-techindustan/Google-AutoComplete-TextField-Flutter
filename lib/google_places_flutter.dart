library google_places_flutter;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_places_flutter/model/prediction.dart';

import 'package:rxdart/subjects.dart';
import 'package:dio/dio.dart';

class GooglePlaceAutoCompleteTextField extends StatefulWidget {
  InputDecoration inputDecoration;
  ItemClick itmClick;
  TextStyle textStyle;
  String googleAPIKey;
  int debounceTime = 600;

  TextEditingController textEditingController = TextEditingController();

  GooglePlaceAutoCompleteTextField(
      {@required this.textEditingController,
      @required this.googleAPIKey,
      this.debounceTime: 600,
      this.inputDecoration: const InputDecoration(),
      this.itmClick,
      this.textStyle: const TextStyle()});

  @override
  _GooglePlaceAutoCompleteTextFieldState createState() =>
      _GooglePlaceAutoCompleteTextFieldState();
}

class _GooglePlaceAutoCompleteTextFieldState
    extends State<GooglePlaceAutoCompleteTextField> {
  final FocusNode _focusNode = FocusNode();
  final subject = new PublishSubject<String>();
  OverlayEntry _overlayEntry;
  List<Prediction> alPredictions = new List();

  TextEditingController controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  bool isSearched = false;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        decoration: widget.inputDecoration,
        style: widget.textStyle,
        controller: widget.textEditingController,
        onChanged: (string) => (subject.add(string)),
      ),
    );
  }

  getLocation(String text) async {
    Dio dio = new Dio();
    String url =
        "https://maps.googleapis.com/maps/api/place/queryautocomplete/json?key=${widget.googleAPIKey}&input=$text";

    Response response = await dio.get(url);
    //print("url"+url);

    print("respinseee" +
        response.statusCode.toString() +
        " " +
        response.data.toString());
    PlacesAutocompleteResponse subscriptionResponse =
        PlacesAutocompleteResponse.fromJson(response.data);
    if (text.length == 0) {
      alPredictions.clear();
      this._overlayEntry.remove();
      return;
    }

    isSearched = false;
    if (subscriptionResponse.predictions.length > 0) {
      alPredictions.clear();
      alPredictions.addAll(subscriptionResponse.predictions);
    }

    //if (this._overlayEntry == null)

    this._overlayEntry = null;
    this._overlayEntry = this._createOverlayEntry();
    Overlay.of(context).insert(this._overlayEntry);
    //   this._overlayEntry.markNeedsBuild();
  }

  @override
  void initState() {
    subject.stream
        .distinct()
        .debounceTime(Duration(milliseconds: widget.debounceTime))
        .listen(textChanged);
  }

  textChanged(String text) async {
    getLocation(text);
  }

  OverlayEntry _createOverlayEntry() {
    if (context != null && context.findRenderObject() != null) {
      RenderBox renderBox = context.findRenderObject();
      var size = renderBox.size;
      var offset = renderBox.localToGlobal(Offset.zero);
      return OverlayEntry(
          builder: (context) => Positioned(
                left: offset.dx,
                top: size.height + offset.dy,
                width: size.width,
                child: CompositedTransformFollower(
                  showWhenUnlinked: false,
                  link: this._layerLink,
                  offset: Offset(0.0, size.height + 5.0),
                  child: Material(
                      elevation: 1.0,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: alPredictions.length,
                        itemBuilder: (BuildContext context, int index) {
                          return InkWell(
                            onTap: () {
                              if (index < alPredictions.length) {
                                widget.itmClick(alPredictions[index]);
                                removeOverlay();
                              }
                              //this._overlayEntry.remove();
                              //controller.text = alPredictions[index].description;
                            },
                            child: Container(
                                padding: EdgeInsets.all(10),
                                child: Text(alPredictions[index].description)),
                          );
                        },
                      )),
                ),
              ));
    }
  }

  removeOverlay() {
    alPredictions.clear();
    this._overlayEntry = this._createOverlayEntry();
    if (context != null) {
      Overlay.of(context).insert(this._overlayEntry);
      this._overlayEntry.markNeedsBuild();
    }
  }
}

PlacesAutocompleteResponse parseResponse(Map responseBody) {
  return PlacesAutocompleteResponse.fromJson(responseBody);
}

typedef ItemClick = void Function(Prediction postalCodeResponse);
