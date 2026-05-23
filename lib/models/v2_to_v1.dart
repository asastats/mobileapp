// V2 -> V1 ASAModel shim.
//
// Lives only during the Phase 5c transition. The provider's V2 fetch
// methods (``getEvaluatedAccountV2``) populate ``_accountV2`` for screens
// that have been migrated to read the V2 model, and also call
// ``v2ToV1ASAModel`` from here to populate ``_asaData`` so screens that
// have NOT been migrated yet keep working. Once every screen reads from
// ``_accountV2`` (end of Phase 5c), Phase 5d deletes this file along
// with ``lib/models/response/`` and the ``_asaData``/``_asaDataSingle``
// fields on the provider.
//
// Field-by-field mapping decisions are documented inline. The most
// important ones up-front:
//
//   * ``v1.Dapps.entries`` is left as ``null``. The V1 entries shape
//     (a structured ``Value/Amount/Price/List<Link>`` object) doesn't
//     map cleanly from the flat ``v2.UserAsaProgram.linked`` list, and
//     per the Phase 5 Q5 answer ("dropped UI features whose data isn't
//     exposed") the widget code is allowed to render nothing for those
//     slots during the transition.
//
//   * ``v1.ASAModel.colors`` is computed here so unmigrated screens keep
//     finding their per-asset color slots. The mapping is
//     ``{asset_id: (asaitem_index % palette_size).toString()}`` with a
//     hard-coded palette size of 18 (matching the bundled
//     ``assets/json/global_settings.json``). Migrated screens compute
//     the color index inline per A7 and don't read this field.
//
//   * Chart fields (``asaChart``, ``nftChart``, ``ratioChart``) are
//     left as ``null``. Per B8, migrated chart widgets compute fl_chart
//     data inline from ``accountV2.asaitems``. Unmigrated chart widgets
//     will render an empty chart, which is acceptable as a transition
//     artifact (we expect the chart widget migration to land in the
//     same screen-migration commit, not a turn later).

import 'response/asa.dart' as v1;
import 'response/asa_model.dart' as v1;
import 'response/dapps.dart' as v1;
import 'response/distribution.dart' as v1;
import 'response/links.dart' as v1;
import 'response/listed.dart' as v1;
import 'response/nftValues.dart' as v1;
import 'response/notEval.dart' as v1;
import 'response/total.dart' as v1;
import 'response/transaction.dart' as v1;
import 'response/values.dart' as v1;
import 'v2/v2.dart' as v2;

/// Mobile-side color palette size. Mirrors the entry count in
/// ``assets/json/global_settings.json`` and matches the website's
/// ``PIE_CHART_MAXIMUM_ITEMS + extras`` row count (the website's palette
/// is 15 + 3 reserved = 18). If the bundled palette ever changes, update
/// this constant — keeping it as a private constant rather than reading
/// from the live settings dict because the palette length is structural
/// (the indexing logic depends on it) and shouldn't change at runtime.
const int _paletteSize = 18;

/// Translate a parsed V2 ``EvaluatedAccount`` into the legacy V1
/// ``ASAModel`` shape. Pure function — no side effects, no Provider
/// state mutation.
v1.ASAModel v2ToV1ASAModel(v2.EvaluatedAccount account) {
  final asaitems = account.asaitems;
  return v1.ASAModel(
    addresses: List<String>.of(account.accountInfo?.addresses ?? const []),
    online: account.accountInfo?.online ?? false,
    warning: account.systemInfo?.warning,
    information: account.systemInfo?.information,
    total: _v2ToV1Total(account.total),
    values: asaitems.map(_v2ToV1Values).toList(),
    nftValues: account.nftcollections.map(_v2ToV1NftValues).toList(),
    notEval: account.notevals.map(_v2ToV1NotEval).toList(),
    colors: _colorMap(asaitems.map((i) => i.asset?.id?.toString()).toList()),
    nftColors: _colorMap(
      account.nftcollections.map((c) => c.name).toList(),
    ),
    // asaChart / nftChart / ratioChart intentionally left null — see
    // file-level comment about B8 and the chart-widget migration.
  );
}

// # Top-level helpers ----------------------------------------------------

/// Build the ``{key: slot_index_string}`` mapping the legacy screens
/// consume via ``asaModel.colors[asset_id]``. Skips entries with a null
/// key (a guard against the rare case where the v2 payload omits
/// ``asset.id``); index counts across all entries to keep slots stable
/// regardless of skipped rows.
Map<String, String> _colorMap(List<String?> keys) {
  final result = <String, String>{};
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    if (key == null) continue;
    result[key] = (i % _paletteSize).toString();
  }
  return result;
}

v1.Total _v2ToV1Total(v2.Total? t) {
  if (t == null) return v1.Total();
  return v1.Total(
    algo: t.algo,
    asa: t.asa,
    nft: t.nft,
    total: t.total,
    totalusdc: t.totalusdc,
    priceusdc: t.priceusdc,
    pricealgo: t.pricealgo,
    noteval: t.noteval,
  );
}

// # AsaItem family ------------------------------------------------------

v1.Values _v2ToV1Values(v2.AsaItem item) {
  return v1.Values(
    value: item.value,
    id: item.asset?.id,
    // V2 amount is int (micro-units), V1 amount is double — same number,
    // different type. Conversion is exact for any sub-2^53 value, which
    // covers every real Algorand asset amount.
    amount: item.amount?.toDouble(),
    price: item.price,
    asa: _v2ToV1Asa(item.asset),
    dapps: item.programs.map(_v2ToV1Dapps).toList(),
  );
}

v1.Asa? _v2ToV1Asa(v2.Asa? a) {
  if (a == null) return null;
  return v1.Asa(
    id: a.id,
    name: a.name,
    // V2 unit is always non-null (empty string sentinel); V1 unit is
    // nullable. Map empty string to null so callers' "is unit set?"
    // checks behave the same as before.
    unit: a.unit.isEmpty ? null : a.unit,
    // V1 stores total as String — historical artifact of the v1
    // serializer JSON-stringifying large integers. V2 keeps it int.
    total: a.total?.toString(),
    decimals: a.decimals,
    url: a.url,
    links: a.links.map(_v2ToV1Links).toList(),
  );
}

v1.Links _v2ToV1Links(v2.OffchainLink l) {
  return v1.Links(
    // V1 ``Links.provider`` is a flat string; V2 ``OffchainLink.provider``
    // is a Provider object. Pull the name out.
    provider: l.provider?.name,
    link: l.link,
  )..title = l.title;
}

v1.Dapps _v2ToV1Dapps(v2.UserAsaProgram p) {
  final program = p.program;
  return v1.Dapps(
    // The legacy ``dapp`` field stored what the website rendered as
    // the row's user-facing label. In V1 that was sometimes the
    // internal code, sometimes the type string. Looking at the V1
    // mobile-app search (the only place ``Dapps.dapp`` is actually
    // read — see provider's searchAsa), it filters on substring match
    // of whatever the user might type — names, types, "balance",
    // "liquidity", etc. The V2 ``program.type`` is the closest
    // searchable signal (e.g. "Balance", "Added", "Locked"). For
    // programs with a more specific name (``program.name`` = e.g.
    // "Liquidity"), we concatenate type + name so both substrings
    // match the search ("Added Liquidity" matches both "added" and
    // "liquidity"). Falls back to the program code as last resort.
    dapp: _dappLabel(program),
    name: program?.name,
    link: program?.url,
    value: p.value,
    amount: p.amount?.toDouble(),
    distribution: p.distribution.map(_v2ToV1Distribution).toList(),
    // The fields below have no V2 equivalent. Leaving them null/empty
    // makes the unmigrated widget code render those slots as blanks,
    // matching the "dropped UI features" decision in Q5.
    //
    //   - ``entries`` (V1 ``Entries`` structure with value/amount/price/
    //     links sub-objects) doesn't map cleanly from the flat
    //     ``linked`` list. See file-level comment. One observable
    //     consequence: the asa_data widget's auto-expand-balance-row
    //     heuristic (which inspects ``entries.value.text`` for
    //     "balance") won't fire under the shim. Users will still be
    //     able to tap to expand manually; the Balance row just no
    //     longer auto-opens on first render. Migrated screens that
    //     read V2 directly should reproduce or drop this UX as
    //     desired.
    //   - ``proxy``, ``address``, ``appId``, ``staking``, ``committed``,
    //     ``reward``, ``next``, ``available``, ``price`` came from
    //     legacy positional fields the V2 serializer doesn't expose.
  );
}

/// Best-effort V1 ``Dapps.dapp`` value derived from a V2 ``AsaProgram``.
/// Returns null only when the program is null — otherwise prefers
/// ``type``, falling back to ``name``, then ``code``.
String? _dappLabel(v2.AsaProgram? p) {
  if (p == null) return null;
  if (p.type != null && p.name != null) {
    return '${p.type} ${p.name}';
  }
  return p.type ?? p.name ?? p.code;
}

v1.Distribution _v2ToV1Distribution(v2.Distribution d) {
  return v1.Distribution(
    value: d.value,
    amount: d.amount?.toDouble(),
    // V2 wraps text/url in a ``DistributionLink`` object; flatten back
    // to V1's parallel scalar fields.
    text: d.link?.text,
    link: d.link?.url,
    // V1 ``price`` had no equivalent in V2; default 0.
  );
}

// # NFT family ----------------------------------------------------------

v1.NftValues _v2ToV1NftValues(v2.NftCollection coll) {
  return v1.NftValues(
    value: coll.value,
    collection: coll.name,
    amount: coll.amount?.toDouble(),
    nfts: coll.nfts.map(_v2ToV1Nfts).toList(),
  );
}

v1.Nfts _v2ToV1Nfts(v2.NftItem item) {
  return v1.Nfts(
    value: item.value,
    id: item.nft?.id,
    amount: item.amount,
    price: item.price,
    creator: item.nft?.creator,
    nft: _v2ToV1Nft(item.nft),
  );
}

v1.Nft? _v2ToV1Nft(v2.Nft? n) {
  if (n == null) return null;
  return v1.Nft(
    id: n.id,
    name: n.name,
    unit: n.unit.isEmpty ? null : n.unit,
    total: n.total,
    // V1 stored image/thumbnail paths under non-obvious names.
    path: n.image,
    tpath: n.thumbnail,
    desc: n.description,
    title: n.title,
    rarity: n.rarity,
    // V1 ``urls`` is a flat ``Map<String, dynamic>`` keyed by URL type
    // (e.g. ``{"image": "...", "Vault": "..."}``). V2 surfaces them as
    // a list of typed objects; collapse into the V1 dict shape.
    urls: {
      for (final u in n.urls)
        if (u.typ != null && u.url != null) u.typ!: u.url!,
    },
    // V1 ``attrs`` is a flat ``Map<String, dynamic>`` of trait
    // name → value. V2 uses a list of ``NftTrait`` objects.
    attrs: {
      for (final t in n.traits)
        if (t.name != null && t.value != null) t.name!: t.value!,
    },
    listed: n.listings.map(_v2ToV1Listed).toList(),
    last: _v2ToV1Transaction(n.lastPurchase),
    max: _v2ToV1Transaction(n.maxPurchase),
    // V1 ``floor`` is a single ``Transaction``; V2 ``floor`` is a list.
    // Take the first entry — the V1 server picked one canonical floor
    // listing, and the V2 list's first entry is the same one (sorted
    // ascending by price, lowest = floor).
    floor: n.floor.isEmpty ? null : _v2ToV1FloorTransaction(n.floor.first),
  );
}

v1.Listed _v2ToV1Listed(v2.NftListing l) {
  return v1.Listed(
    price: l.price,
    text: l.market?.name,
    link: l.link,
  );
}

v1.Transaction? _v2ToV1Transaction(v2.NftPurchase? p) {
  if (p == null) return null;
  return v1.Transaction(
    price: p.price,
    text: p.market?.name,
    link: p.link,
    epoch: p.epoch,
  );
}

/// Floor entries are ``NftListing`` (no epoch), not ``NftPurchase``, but
/// V1 expects a ``Transaction`` (which has an epoch slot). Map without
/// an epoch — the V1 widget code reads ``floor.epoch`` defensively
/// (``?? 0``).
v1.Transaction _v2ToV1FloorTransaction(v2.NftListing l) {
  return v1.Transaction(
    price: l.price,
    text: l.market?.name,
    link: l.link,
  );
}

// # Noteval -------------------------------------------------------------

v1.NotEval _v2ToV1NotEval(v2.NotEvaluatedItem item) {
  return v1.NotEval(
    asa: _v2ToV1Asa(item.asset),
    amount: item.amount?.toDouble(),
    dapps: item.programs.map(_v2ToV1Dapps).toList(),
    // V1 ``id``, ``value``, ``price`` weren't part of the V2 noteval
    // serializer (notevals don't have a value by definition). Default
    // null/0 — V1 widgets read these defensively.
  );
}
