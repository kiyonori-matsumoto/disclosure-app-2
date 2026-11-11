## 2023-10-24 - Optimizing List Filtering with Pre-computed Regex and String Conversion
**Learning:** In the `lib/bloc/bloc.dart` filtering logic, the `Company.match` method was calling `hiraToKana` for every item in a large list during a `where` loop. The `hiraToKana` method was creating a new `RegExp` object on every call. Pre-computing the regex object (making it `static final`) and extracting the `hiraToKana` call out of the loop and passing the pre-converted string to the `match` method reduced the processing time for filtering 4000 items from ~8000ms to ~300ms in isolated benchmarks, representing a ~95% reduction in execution time for large lists.
**Action:** When filtering lists using search terms, always extract string manipulations (like case conversions or kana conversions) and pre-compile regular expressions outside the loop to prevent redundant, expensive computations per list item.

## 2023-10-28 - Avoid O(N) array lookups in stream mappers
**Learning:** RxDart streams that combine a list of strings (e.g. favorite codes) with a list of domain objects (e.g. Companies) can lead to O(M*N) performance if linear search (`firstWhere`) is used inside the `map` callback.
**Action:** When filtering or mapping items based on an ID, pre-compute a dictionary (`Map<String, Model>`) keyed by the ID for O(1) lookups instead of keeping the full domain objects list. Make sure to handle null keys carefully when creating maps.

## 2025-02-18 - Avoid O(N) stream list search when O(1) map is available in BLoC
**Learning:** In the disclosure app's architecture, when looking up companies (e.g. mapping codes to Company objects inside streams like those in `SettlementsList` and `AppBloc`), iterating over `companies` lists with methods like `firstWhere` (an O(N) operation) creates unnecessary performance bottlenecks, especially when triggered on every stream event. We already have `companyCodeMap$` and `companyMap$` specifically exposed to provide instant access.
**Action:** When performing stream processing or list transformations that require company lookups, always utilize `companyCodeMap$` or `companyMap$` for O(1) map lookups instead of iterating over the `company$` list.

## 2025-02-18 - Avoid O(N) list lookups in Array `.where` loop
**Learning:** In Riverpod providers, such as `disclosures_provider.dart`, when filtering items based on an ID being in a list (e.g. `favoriteCompanyCodes.contains(code)` inside a `.where` loop over `feed.displayedDocs`), the `contains` operation on a List is O(N). This leads to O(M*N) performance where M is the number of documents and N is the number of favorite companies.
**Action:** Always pre-compute a `Set` (e.g. `favorites.toSet()`) outside the loop, changing the `.contains()` check to O(1) inside the filtering function. This simple change avoids redundant iterations and provides significant performance improvements for large datasets.
