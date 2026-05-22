// NFT-side models — a single file because the seven NFT classes are
// tightly coupled and individually small. Mirrors the contiguous block of
// NFT serializers in api/serializers.py (NftCurrencySerializer through
// NftCollectionSerializer).

import '_json.dart';
import 'asa.dart';
import 'provider.dart';

/// Currency that an NFT listing or purchase was denominated in. Surfaces
/// the originating asset (ALGO, USDC, etc.) and the amount of that asset.
class NftCurrency {
  final int? amount;
  final Asa? asset;

  NftCurrency({this.amount, this.asset});

  factory NftCurrency.fromJson(Map<String, dynamic> json) => NftCurrency(
        amount: parseInt(json['amount']),
        asset: parseObject(json['asset'], Asa.fromJson),
      );

  Map<String, dynamic> toJson() => {
        if (amount != null) 'amount': amount,
        if (asset != null) 'asset': asset!.toJson(),
      };
}

/// An NFT listed for sale on some market.
class NftListing {
  final double? price;
  final Provider? market;
  final String? link;
  final NftCurrency? currency;

  NftListing({this.price, this.market, this.link, this.currency});

  factory NftListing.fromJson(Map<String, dynamic> json) => NftListing(
        price: parseDouble(json['price']),
        market: parseObject(json['market'], Provider.fromJson),
        link: parseString(json['link']),
        currency: parseObject(json['currency'], NftCurrency.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'price': price,
        if (market != null) 'market': market!.toJson(),
        if (link != null) 'link': link,
        if (currency != null) 'currency': currency!.toJson(),
      };
}

/// A historical purchase of an NFT — last or max trade. Identical shape
/// to [NftListing] except with an additional ``epoch`` timestamp.
class NftPurchase {
  final double? price;
  final Provider? market;
  final String? link;

  /// Unix epoch seconds when the purchase happened.
  final int? epoch;

  final NftCurrency? currency;

  NftPurchase({
    this.price,
    this.market,
    this.link,
    this.epoch,
    this.currency,
  });

  factory NftPurchase.fromJson(Map<String, dynamic> json) => NftPurchase(
        price: parseDouble(json['price']),
        market: parseObject(json['market'], Provider.fromJson),
        link: parseString(json['link']),
        epoch: parseInt(json['epoch']),
        currency: parseObject(json['currency'], NftCurrency.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'price': price,
        if (market != null) 'market': market!.toJson(),
        if (link != null) 'link': link,
        if (epoch != null) 'epoch': epoch,
        if (currency != null) 'currency': currency!.toJson(),
      };
}

/// One key-value pair from an NFT's traits metadata.
class NftTrait {
  final String? name;
  final String? value;

  NftTrait({this.name, this.value});

  factory NftTrait.fromJson(Map<String, dynamic> json) => NftTrait(
        name: parseString(json['name']),
        value: parseString(json['value']),
      );

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (value != null) 'value': value,
      };
}

/// One URL entry from an NFT's metadata.
///
/// ``typ`` is the URL category: ``"image"``, ``"animation_url"``, ``"Vault"``
/// (locked NFTs), ``"Pera Asset Inbox"``, ``"external_url"``, ``"Template"``
/// (for ARC-19 templating), etc. The website's ``nfts/item.html`` template
/// special-cases ``typ == 'Vault'`` and ``typ == 'Locked'`` to render the
/// secondary URL instead of the primary one.
class NftUrl {
  final String? typ;
  final String? url;

  NftUrl({this.typ, this.url});

  factory NftUrl.fromJson(Map<String, dynamic> json) => NftUrl(
        typ: parseString(json['typ']),
        url: parseString(json['url']),
      );

  Map<String, dynamic> toJson() => {
        if (typ != null) 'typ': typ,
        if (url != null) 'url': url,
      };
}

/// Static NFT metadata. Carries the visual paths plus the trade history
/// (listings, last/max purchase, floor price).
class Nft {
  final int? id;
  final String? name;

  /// Same "empty string is meaningful" treatment as [Asa.unit].
  final String unit;
  final int? total;
  final int? decimals;
  final String? creator;

  /// Relative path under ``static/`` for the full-size image.
  /// Use ``AppConstants.getNFTImage()`` to absolutize.
  final String? image;

  /// Relative path under ``static/`` for the small thumbnail.
  final String? thumbnail;

  final List<NftUrl> urls;
  final List<NftListing> listings;

  /// Floor listings — currently lives on each NFT, will be moved to the
  /// containing [NftCollection] in a future API version. Until that
  /// migration happens, every NFT in a collection has the same floor
  /// list (the collection's floor), so consumers can read it from any
  /// member NFT.
  final List<NftListing> floor;

  final NftPurchase? lastPurchase;
  final NftPurchase? maxPurchase;
  final String? title;
  final String? description;
  final String? rarity;
  final List<NftTrait> traits;

  Nft({
    this.id,
    this.name,
    this.unit = '',
    this.total,
    this.decimals,
    this.creator,
    this.image,
    this.thumbnail,
    this.urls = const [],
    this.listings = const [],
    this.floor = const [],
    this.lastPurchase,
    this.maxPurchase,
    this.title,
    this.description,
    this.rarity,
    this.traits = const [],
  });

  factory Nft.fromJson(Map<String, dynamic> json) => Nft(
        id: parseInt(json['id']),
        name: parseString(json['name']),
        unit: parseString(json['unit']) ?? '',
        total: parseInt(json['total']),
        decimals: parseInt(json['decimals']),
        creator: parseString(json['creator']),
        image: parseString(json['image']),
        thumbnail: parseString(json['thumbnail']),
        urls: parseList(json['urls'], NftUrl.fromJson),
        listings: parseList(json['listings'], NftListing.fromJson),
        floor: parseList(json['floor'], NftListing.fromJson),
        lastPurchase: parseObject(json['last_purchase'], NftPurchase.fromJson),
        maxPurchase: parseObject(json['max_purchase'], NftPurchase.fromJson),
        title: parseString(json['title']),
        description: parseString(json['description']),
        rarity: parseString(json['rarity']),
        traits: parseList(json['traits'], NftTrait.fromJson),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        'unit': unit,
        if (total != null) 'total': total,
        if (decimals != null) 'decimals': decimals,
        if (creator != null) 'creator': creator,
        if (image != null) 'image': image,
        if (thumbnail != null) 'thumbnail': thumbnail,
        'urls': urls.map((u) => u.toJson()).toList(),
        'listings': listings.map((l) => l.toJson()).toList(),
        'floor': floor.map((l) => l.toJson()).toList(),
        if (lastPurchase != null) 'last_purchase': lastPurchase!.toJson(),
        if (maxPurchase != null) 'max_purchase': maxPurchase!.toJson(),
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (rarity != null) 'rarity': rarity,
        'traits': traits.map((t) => t.toJson()).toList(),
      };

  /// Convenience: the URL the website's item template uses for the
  /// "view original" image link. Vault- or Locked-typed URLs are skipped
  /// because they point to escrow contracts rather than the actual image.
  NftUrl? get primaryImageUrl {
    if (urls.isEmpty) return null;
    final first = urls.first;
    if (first.typ == 'Vault' || first.typ == 'Locked') {
      return urls.length > 1 ? urls[1] : null;
    }
    return first;
  }
}

/// The user's holding within one NFT collection — typically a wallet
/// holds multiple NFTs from the same collection. One [NftItem] per
/// distinct NFT id; the user's per-NFT amount is in ``amount``.
class NftItem {
  final double? value;
  final Nft? nft;

  /// Number of copies owned. 1 for the typical 1-of-N case.
  final int? amount;

  final double? price;

  NftItem({this.value, this.nft, this.amount, this.price});

  factory NftItem.fromJson(Map<String, dynamic> json) => NftItem(
        value: parseDouble(json['value']),
        nft: parseObject(json['nft'], Nft.fromJson),
        amount: parseInt(json['amount']),
        price: parseDouble(json['price']),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        if (nft != null) 'nft': nft!.toJson(),
        'amount': amount,
        'price': price,
      };
}

/// A grouping of NFTs that share a collection name. The list lives at
/// ``EvaluatedAccount.nftcollections``, ordered by collection value
/// descending (valued first, unvalued — value=0 — last).
class NftCollection {
  final double? value;
  final String? name;

  /// Total number of NFTs from this collection held by the bundle.
  final int? amount;

  final List<NftItem> nfts;

  NftCollection({this.value, this.name, this.amount, this.nfts = const []});

  factory NftCollection.fromJson(Map<String, dynamic> json) => NftCollection(
        value: parseDouble(json['value']),
        name: parseString(json['name']),
        amount: parseInt(json['amount']),
        nfts: parseList(json['nfts'], NftItem.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        if (name != null) 'name': name,
        'amount': amount,
        'nfts': nfts.map((n) => n.toJson()).toList(),
      };
}
