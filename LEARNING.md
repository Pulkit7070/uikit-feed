# Learning guide

This guide walks through FeedKit Demo in the order it is best read. Part 1 goes file by file. Part 2 explains the UIKit ideas the app is built on. Part 3 is a set of interview questions with short answers. Every answer links to the exact file and line.

Line numbers match the code at the commit that added this guide. If you change a file, the numbers will drift.

## Part 1: The code in reading order

### 1. `FeedKitDemo/App/AppDelegate.swift`

This is where the app starts (`@main`). It does one job: it tells UIKit which class manages each window ([AppDelegate.swift:8-16](FeedKitDemo/App/AppDelegate.swift#L8-L16)). Apps made from Xcode's template do this through `Info.plist` and a storyboard. This app has neither, so it does it in code.

### 2. `FeedKitDemo/App/SceneDelegate.swift`

When the window is about to appear, UIKit calls `scene(_:willConnectTo:options:)`. We create a `UIWindow`, put a `UINavigationController` inside it with `FeedViewController` as the first screen, and call `makeKeyAndVisible()` ([SceneDelegate.swift:14-17](FeedKitDemo/App/SceneDelegate.swift#L14-L17)). Keep a strong reference in `self.window`, or the window is freed and the screen goes black.

### 3. `FeedKitDemo/Models/Photo.swift`

One photo from Picsum. It is `Codable`, so `JSONDecoder` can fill it in from JSON. The JSON key `download_url` does not follow Swift naming, so `CodingKeys` maps it to `downloadURL` ([Photo.swift:13-16](FeedKitDemo/Models/Photo.swift#L13-L16)). `resizedURL(width:)` asks Picsum for a smaller file ([Photo.swift:20](FeedKitDemo/Models/Photo.swift#L20)). `aspectRatio` lets a card reserve the right height before the image arrives ([Photo.swift:26](FeedKitDemo/Models/Photo.swift#L26)).

### 4. `FeedKitDemo/Models/Video.swift`

A title and a URL, plus a fixed list of five sample clips ([Video.swift:11](FeedKitDemo/Models/Video.swift#L11)). Each URL was checked to return a real MP4 before it was added.

### 5. `FeedKitDemo/Models/FeedItem.swift`

Everything the feed can show: a photo or a video. The important part is the nested `ID` type ([FeedItem.swift:12-17](FeedKitDemo/Models/FeedItem.swift#L12-L17)). The list stores only these IDs, never the items themselves. A video's ID is its position in the feed (`slot`), because the same clip appears many times.

### 6. `FeedKitDemo/Networking/APIClient.swift`

`PhotoFetching` is a one-method protocol ([APIClient.swift:5-7](FeedKitDemo/Networking/APIClient.swift#L5-L7)). `APIClient` is the real version. It builds the URL with `URLComponents` and calls a small generic `get` ([APIClient.swift:31-37](FeedKitDemo/Networking/APIClient.swift#L31-L37)). That function downloads with `try await session.data(from:)`, throws on a status code outside 200 to 299, and decodes JSON into whatever `Decodable` type the caller asks for.

### 7. `FeedKitDemo/Feed/FeedViewModel.swift`

This is the brain of the feed, so read it slowly.

- `LoadState` names the four situations the feed can be in ([FeedViewModel.swift:9-17](FeedKitDemo/Feed/FeedViewModel.swift#L9-L17)). Using one enum means the feed cannot be "loading" and "failed" at the same time.
- The view controller can read `carouselIDs`, `feedIDs` and `loadState` but cannot change them, because they are `private(set)` ([FeedViewModel.swift:23-25](FeedKitDemo/Feed/FeedViewModel.swift#L23-L25)).
- `loadNextPage()` does nothing unless the state is `.idle` ([FeedViewModel.swift:49-52](FeedKitDemo/Feed/FeedViewModel.swift#L49-L52)). That one guard stops double loading, stops loading after the end, and stops automatic retries after a failure.
- `load(page:replacingExisting:)` does the work ([FeedViewModel.swift:66-86](FeedKitDemo/Feed/FeedViewModel.swift#L66-L86)). The `requestNumber` check at line 74 drops a response if a newer request started in the meantime. That is how a refresh wins over a page that was still loading.
- `append(_:)` puts the first 8 photos in the carousel, the rest in the list, and inserts a video after every sixth list photo ([FeedViewModel.swift:96-119](FeedKitDemo/Feed/FeedViewModel.swift#L96-L119)). It skips IDs it has already seen (line 100), because a diffable data source crashes on duplicates.

### 8. `FeedKitDemo/Feed/FeedLayout.swift`

`FeedLayout.make` returns a compositional layout that picks a section design per section index ([FeedLayout.swift:17-25](FeedKitDemo/Feed/FeedLayout.swift#L17-L25)).

- The carousel has one item per group, and each group is 80% of the width and 220 points tall ([FeedLayout.swift:34-37](FeedKitDemo/Feed/FeedLayout.swift#L34-L37)). The line that makes it scroll sideways is `orthogonalScrollingBehavior = .groupPagingCentered` ([FeedLayout.swift:41](FeedKitDemo/Feed/FeedLayout.swift#L41)).
- The feed uses `.estimated(300)` heights so each card can size itself ([FeedLayout.swift:49](FeedKitDemo/Feed/FeedLayout.swift#L49)). It also adds a footer for the spinner and the Retry button ([FeedLayout.swift:57-62](FeedKitDemo/Feed/FeedLayout.swift#L57-L62)).

The enum is `@MainActor` (line 10) because UIKit layout objects may only be used on the main thread.

### 9. `FeedKitDemo/Feed/FeedViewController.swift`

Read it in this order.

- **Set-up in `viewDidLoad`** ([FeedViewController.swift:19-34](FeedKitDemo/Feed/FeedViewController.swift#L19-L34)). It builds the collection view and the data source, subscribes to `onChange`, and asks for page 1.
- **Pull to refresh** ([FeedViewController.swift:72-74](FeedKitDemo/Feed/FeedViewController.swift#L72-L74) and [54-59](FeedKitDemo/Feed/FeedViewController.swift#L54-L59)). A `UIRefreshControl` calls `refresh()`, which awaits the view model and then stops the spinner.
- **Cell registrations and the data source** ([FeedViewController.swift:77-118](FeedKitDemo/Feed/FeedViewController.swift#L77-L118)). The data source gets an ID, looks up the item in the view model, and picks the right cell type. The closure captures `viewModel` rather than `self` (line 89), so it does not create a retain cycle.
- **`applySnapshot()`** ([FeedViewController.swift:131-139](FeedKitDemo/Feed/FeedViewController.swift#L131-L139)). It builds a fresh snapshot from the view model's IDs and applies it. UIKit animates the differences.
- **`updateFooter()`** ([FeedViewController.swift:122-129](FeedKitDemo/Feed/FeedViewController.swift#L122-L129)). The footer is not an item in the snapshot, so it is updated by hand.
- **`updateVideoPlayback()`** ([FeedViewController.swift:143-162](FeedKitDemo/Feed/FeedViewController.swift#L143-L162)). It finds the most visible video card, plays it if at least 60% shows, and pauses the rest.
- **The delegate methods** ([FeedViewController.swift:165-203](FeedKitDemo/Feed/FeedViewController.swift#L165-L203)). They load the next page near the end, push the detail screen on tap, pause a video when its card leaves the screen, and re-check playback on every scroll.

### 10. The cells in `FeedKitDemo/Feed/Cells/`

- `CarouselCell` and `PhotoCardCell` build their views once in `init(frame:)`. `configure(with:)` fills them in for one photo ([PhotoCardCell.swift:51-70](FeedKitDemo/Feed/Cells/PhotoCardCell.swift#L51-L70)). Both cancel their image load in `prepareForReuse` ([PhotoCardCell.swift:74-77](FeedKitDemo/Feed/Cells/PhotoCardCell.swift#L74-L77), [CarouselCell.swift:58-61](FeedKitDemo/Feed/Cells/CarouselCell.swift#L58-L61)).
- `PhotoCardCell` sets an aspect-ratio constraint at priority 999 ([PhotoCardCell.swift:64](FeedKitDemo/Feed/Cells/PhotoCardCell.swift#L64)). With 1000, Auto Layout would log a conflict while the cell still has its estimated height.
- `VideoCardCell` makes a muted `AVQueuePlayer` and an `AVPlayerLooper` ([VideoCardCell.swift:60-68](FeedKitDemo/Feed/Cells/VideoCardCell.swift#L60-L68)). It throws them away in `prepareForReuse` ([VideoCardCell.swift:78-84](FeedKitDemo/Feed/Cells/VideoCardCell.swift#L78-L84)). `PlayerView` overrides `layerClass` so its own layer is an `AVPlayerLayer` ([VideoCardCell.swift:91](FeedKitDemo/Feed/Cells/VideoCardCell.swift#L91)).
- `LoadingFooterView.show(_:)` turns a `LoadState` into a spinner or a Retry button ([LoadingFooterView.swift:44](FeedKitDemo/Feed/Cells/LoadingFooterView.swift#L44)).

### 11. `FeedKitDemo/Images/`

Read these four files in this order.

1. `ImageCache.swift` wraps `NSCache` with three methods. Each image's cost is its decoded byte size ([ImageCache.swift:35-38](FeedKitDemo/Images/ImageCache.swift#L35-L38)), so `totalCostLimit` really is a memory limit.
2. `ImageDownsampler.swift` opens the data without decoding it (line 13), then asks ImageIO for a thumbnail no bigger than the view in pixels ([ImageDownsampler.swift:18-27](FeedKitDemo/Images/ImageDownsampler.swift#L18-L27)).
3. `ImageLoader.swift` is an `actor` ([ImageLoader.swift:11](FeedKitDemo/Images/ImageLoader.swift#L11)). `image(for:pointSize:scale:)` checks the cache, downloads, checks for cancellation, downsamples, and caches ([ImageLoader.swift:29-44](FeedKitDemo/Images/ImageLoader.swift#L29-L44)). The cache key includes the pixel size (line 47).
4. `RemoteImageView.swift` keeps the current load `Task` ([RemoteImageView.swift:6](FeedKitDemo/Images/RemoteImageView.swift#L6)). It uses a cached image right away if there is one (line 14). Otherwise it starts a Task and, when the image arrives, sets it only if the Task was not cancelled ([RemoteImageView.swift:22-28](FeedKitDemo/Images/RemoteImageView.swift#L22-L28)).

### 12. `FeedKitDemo/Detail/PhotoDetailViewController.swift`

A scroll view holding a vertical stack: image, author, size, and a button. The image view's height is tied to the photo's aspect ratio ([PhotoDetailViewController.swift:71](FeedKitDemo/Detail/PhotoDetailViewController.swift#L71)). The image is loaded in `viewDidLayoutSubviews`, once, after Auto Layout has given the view its real size ([PhotoDetailViewController.swift:75-82](FeedKitDemo/Detail/PhotoDetailViewController.swift#L75-L82)).

### 13. `FeedKitDemoTests/`

- `FakePhotoFetcher` is an `actor` that returns prepared results and records which pages were requested ([FeedViewModelTests.swift:6-18](FeedKitDemoTests/FeedViewModelTests.swift#L6-L18)). The tests check real outcomes, such as which IDs ended up where and which pages were fetched.
- `ImageCacheTests` checks the cache, and also checks that downsampling a 2000 × 1000 image to 100 × 50 points at 2x gives exactly 200 × 100 pixels ([ImageCacheTests.swift:40-49](FeedKitDemoTests/ImageCacheTests.swift#L40-L49)).

## Part 2: Key ideas

### Cell reuse

A collection view does not make one cell per item. It makes roughly enough cells to fill the screen and reuses them as you scroll. A cell that scrolls off the top comes back at the bottom showing a different item. This saves memory and time, but anything a cell started for its old item can finish later and land on the new one. The classic bug is an image download that finishes after the cell was reused, so the wrong photo appears. UIKit calls `prepareForReuse()` just before a cell is reused. That is where this app cancels the image Task and stops the video player. `RemoteImageView` also checks `Task.isCancelled` after the download. That check matters: cancelling a Task only asks it to stop, and the code after an `await` must still look before it acts.

### Diffable data source

The old way to feed a collection view was to answer "how many items?" and "what is item N?", then call `insertItems` or `reloadData` and keep the numbers in sync yourself. Getting it wrong crashed the app. With `UICollectionViewDiffableDataSource`, you describe what the list should look like right now (a snapshot of sections and item IDs) and call `apply`. UIKit compares it with the previous snapshot and works out the inserts, deletes and moves itself. The IDs must be `Hashable` and unique, and they should stay the same for the same item over time. That is why this app stores `FeedItem.ID` values, not whole items, and looks the item up when a cell is needed.

### Compositional layout

`UICollectionViewCompositionalLayout` builds a layout from three nested pieces. An item is one cell. A group is a row or column of items. A section is a run of groups. Sizes can be a fraction of the container (`.fractionalWidth(0.8)`), fixed (`.absolute(220)`), or estimated (`.estimated(300)`). Estimated means "start with this guess, then let the cell's Auto Layout decide." Setting `orthogonalScrollingBehavior` on a section makes that one section scroll sideways inside a list that scrolls up and down. No nested collection view is needed.

### NSCache

`NSCache` is like a dictionary, with three differences that matter for images. It removes entries by itself when it goes over `countLimit` or `totalCostLimit`. It also removes them when the system is low on memory. And it is safe to use from several threads at once. Because the cache can drop anything at any time, code must always be ready for a cache miss. That is fine for images, because a miss only means downloading again.

### Downsampling

The size of a JPEG file says little about the memory it needs once it is shown. A decoded image takes width × height × 4 bytes. A 5000 × 3333 photo is about 66 MB, even when it is shown in a card 350 points wide. `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize` decodes straight to a smaller size, so the full bitmap never exists. The target is in pixels, so the view's size in points is multiplied by the screen scale (2x or 3x).

### async/await and the main actor

UIKit must only be touched from the main thread. Swift expresses that with the main actor: `UIView` and `UIViewController` are `@MainActor`, and so is `FeedViewModel` ([FeedViewModel.swift:6](FeedKitDemo/Feed/FeedViewModel.swift#L6)). A `Task { }` started from main-actor code runs on the main actor too. When that code reaches `await`, it gives up the main thread while it waits. The slow work runs elsewhere, for example inside the `ImageLoader` actor or inside `URLSession`. When the work is done, the code continues on the main actor, so the next line can safely set `imageView.image`. Nothing calls `DispatchQueue.main.async` by hand. The compiler checks this in Swift 6 mode, and that is how the build caught `FeedLayout` missing `@MainActor`.

## Part 3: Interview questions

**1. How does the app start without a storyboard?**
`AppDelegate` returns a `UISceneConfiguration` whose `delegateClass` is `SceneDelegate` ([AppDelegate.swift:14](FeedKitDemo/App/AppDelegate.swift#L14)). `SceneDelegate` creates the window and its root view controller in code ([SceneDelegate.swift:14-17](FeedKitDemo/App/SceneDelegate.swift#L14-L17)).

**2. Why does the data source store `FeedItem.ID` and not `FeedItem`?**
The diffable data source compares snapshots by hash and equality. An ID stays the same for the life of an item, so UIKit sees "same item" instead of "deleted and inserted" ([FeedItem.swift:12-17](FeedKitDemo/Models/FeedItem.swift#L12-L17)). The cell provider looks the full item up by ID ([FeedViewController.swift:91](FeedKitDemo/Feed/FeedViewController.swift#L91)).

**3. Why is the video ID a slot number and not the video URL?**
Five clips repeat throughout the feed, so a URL is not unique, and duplicate IDs crash a diffable data source. The slot is unique ([FeedViewModel.swift:113](FeedKitDemo/Feed/FeedViewModel.swift#L113)).

**4. How does the carousel scroll sideways inside a vertical list?**
`section.orthogonalScrollingBehavior = .groupPagingCentered` on the carousel section ([FeedLayout.swift:41](FeedKitDemo/Feed/FeedLayout.swift#L41)). The group is 80% wide (line 35), so the next card peeks in.

**5. How do the feed cards get the right height?**
The layout uses `.estimated(300)` ([FeedLayout.swift:49](FeedKitDemo/Feed/FeedLayout.swift#L49)). Each card's constraints decide its real height. The image view's height equals its width × the photo's aspect ratio ([PhotoCardCell.swift:59-65](FeedKitDemo/Feed/Cells/PhotoCardCell.swift#L59-L65)).

**6. What stops a reused cell from showing the wrong image?**
`prepareForReuse` calls `cancelLoad()` ([PhotoCardCell.swift:74-77](FeedKitDemo/Feed/Cells/PhotoCardCell.swift#L74-L77)). After the download, the Task checks `Task.isCancelled` before it sets the image ([RemoteImageView.swift:26](FeedKitDemo/Images/RemoteImageView.swift#L26)). `setImage` also cancels any earlier load before it starts a new one (line 9).

**7. Why is the cache key the URL plus the pixel size?**
The same photo can be shown at different sizes, for example the 800-wide card and the 1200-wide detail view. A thumbnail made for one size would look blurry at the other ([ImageLoader.swift:47-51](FeedKitDemo/Images/ImageLoader.swift#L47-L51)).

**8. What does downsampling save, and how is it done?**
It avoids decoding the full image. A 5000 × 3333 photo would take about 66 MB. `CGImageSourceCreateThumbnailAtIndex` with a maximum pixel size decodes only what the view needs ([ImageDownsampler.swift:18-27](FeedKitDemo/Images/ImageDownsampler.swift#L18-L27)).

**9. Why is `ImageLoader` an actor?**
An actor's methods run off the main thread, one at a time. Downloading and decoding never block scrolling, and the shared state is safe without locks ([ImageLoader.swift:11](FeedKitDemo/Images/ImageLoader.swift#L11)). `cachedImage` is `nonisolated`, so a cell can check the cache right away without awaiting (line 25).

**10. How does pagination avoid loading the same page twice?**
`loadNextPage()` returns early unless `loadState == .idle` ([FeedViewModel.swift:50](FeedKitDemo/Feed/FeedViewModel.swift#L50)). While a page loads the state is `.loading`, so the many `willDisplay` calls near the end ([FeedViewController.swift:169-175](FeedKitDemo/Feed/FeedViewController.swift#L169-L175)) do nothing.

**11. What happens when a page fails to load?**
The state becomes `.failed` ([FeedViewModel.swift:83](FeedKitDemo/Feed/FeedViewModel.swift#L83)), and the footer shows a Retry button ([LoadingFooterView.swift:44-54](FeedKitDemo/Feed/Cells/LoadingFooterView.swift#L44-L54)). Scrolling does not retry by itself. Tapping Retry calls `retry()`, which moves back to `.idle` and loads the same page ([FeedViewModel.swift:60-64](FeedKitDemo/Feed/FeedViewModel.swift#L60-L64)). `testFailureWaitsForRetryThenLoadsTheSamePage` checks this ([FeedViewModelTests.swift:80](FeedKitDemoTests/FeedViewModelTests.swift#L80)).

**12. What if the user pulls to refresh while a page is still loading?**
Every request takes a new `requestNumber`. When the older page arrives, its number is no longer current, so it is dropped ([FeedViewModel.swift:67-74](FeedKitDemo/Feed/FeedViewModel.swift#L67-L74)). Only the refreshed page 1 is shown.

**13. How does the app make sure only one video plays?**
On every scroll, `updateVideoPlayback()` measures what share of each visible video card is on screen. It plays the largest share, if it is at least 60%, and pauses every other one ([FeedViewController.swift:143-162](FeedKitDemo/Feed/FeedViewController.swift#L143-L162)). Cards also pause when they leave the screen (line 196) and when the feed is covered (lines 41-46).

**14. Why does the data source closure capture `viewModel` instead of `self`?**
The view controller owns the data source, and the data source owns its closure. If the closure held `self` strongly, the two would keep each other alive forever (a retain cycle). The view model does not own the data source, so capturing it is safe ([FeedViewController.swift:88-90](FeedKitDemo/Feed/FeedViewController.swift#L88-L90)).

**15. How is the view model tested without the network?**
It depends on the `PhotoFetching` protocol ([APIClient.swift:5](FeedKitDemo/Networking/APIClient.swift#L5)), not on `APIClient`. The tests pass in `FakePhotoFetcher`, which returns prepared pages or errors and records which pages were asked for ([FeedViewModelTests.swift:6-18](FeedKitDemoTests/FeedViewModelTests.swift#L6-L18)).

**Bonus: what would you improve next?**
Three honest gaps. The downsampler fits the longer side of the view, so an aspect-fill image cropped into a different shape can be slightly softer than it could be ([ImageDownsampler.swift:18](FeedKitDemo/Images/ImageDownsampler.swift#L18)). Two cells asking for the same image at the same moment both download it, because in-flight requests are not shared. And there is no disk cache, so images download again after the app restarts.
