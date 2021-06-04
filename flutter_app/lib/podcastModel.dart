class Podcast {
  String name;
  num price;
  int id;

  Podcast({required this.name, required this.price, required this.id});

  Podcast.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        price = json["price"],
        id = json["id"];
}
