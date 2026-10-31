Analyzed SKILL.md:L1-103
Analyzed main.dart:L1-100
Analyzed main.dart:L101-215
Analyzed pos_provider.dart:L1-100
Analyzed pos_provider.dart:L101-350
Analyzed pos_provider.dart:L351-500
Analyzed pos_provider.dart:L501-731
Analyzed database_service.dart:L1-80
Analyzed repositories.dart:L1-100
Analyzed models.dart:L115-160
Analyzed models.dart:L270-320
Analyzed models.dart:L440-500
Ran search class OrderItem
Analyzed models.dart:L840-880
Analyzed repositories.dart:L390-480
Analyzed models.dart:L730-790
Ran list all files in lib
Analyzed promptpay_service.dart:L1-70
Ran scan for TODOs and catches in views
Analyzed index.html:L1-50
Ran check settlement test case
Ran grep commission in plan_v1.7.md
Analyzed repositories.dart:L320-360
Analyzed repositories.dart:L300-325
Analyzed repositories.dart:L150-175
Ran check getActiveEvent
Ran check deleteCategory
Ran grep deleteCategory callers
Analyzed firestore.rules:L1-90
Analyzed repositories.dart:L365-388
Analyzed models.dart:L680-730
Ran check voidOrder in history_screen
Ran check voidOrder in database_service
Analyzed database_service.dart:L355-375
Ran check permissions in inventory_screen
Ran check _showProductDialog in inventory_screen
Analyzed inventory_screen.dart:L340-400

What this repo does: An offline-first Flutter point-of-sale app for art-fair booths. It handles multi-artist sales, inventory, PromptPay QR, stock tracking, and financial settlements. Assumed load: 1–3 staff devices per booth selling ~200 orders per day under unstable event Wi-Fi.

---

### Must fix

1. **Product cost exposed to managers in edit dialog** ([lib/views/inventory_screen.dart:L389-396](file:///e:/pitchaya_project/Mypos/lib/views/inventory_screen.dart#L389-L396))
   - **What this is:** Dialog for adding and editing product information.
   - **Problem:** The cost field displays and saves for any user who can edit the product, ignoring `pos.canViewCost(product)`. A manager can see confidential costs of co-host artists.
   - **Fix:** Hide the cost input widget when `!pos.canViewCost(product)` and preserve the existing cost on save.
   - **If we skip it:** Sharing a booth exposes private wholesale costs to other artists.

2. **Deleting category affects all shops** ([lib/providers/pos_provider.dart:L494-500](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L494-L500), [lib/repositories/repositories.dart:L253-255](file:///e:/pitchaya_project/Mypos/lib/repositories/repositories.dart#L253-L255))
   - **What this is:** Reassigns products to uncategorized when their category is deleted.
   - **Problem:** Callers do not pass `shopId` to `_db.deleteCategory`, so `getProducts(shopId: null)` iterates and updates matching category IDs across every shop in the database.
   - **Fix:** Pass `_currentShopId` to `deleteCategory` in both `PosProvider` and `LocalRepositoryRegistry`.
   - **If we skip it:** Deleting a category in Shop A can reset categories for products in Shop B.

3. **Stale stock snapshot overwrites inventory on checkout** ([lib/providers/pos_provider.dart:L452-458](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L452-L458))
   - **What this is:** Deducts sold item quantities from inventory during checkout.
   - **Problem:** It computes `cartItem.product.stock - cartItem.qty` from the cart item snapshot instead of re-reading fresh stock from the database.
   - **Fix:** Read the current product from `_db.getProduct(cartItem.product.id)` before subtracting `cartItem.qty` (as done in `repositories.dart:L315-323`).
   - **If we skip it:** If stock was adjusted while an item sat in the cart, checkout overwrites that adjustment.

4. **Firestore list rules reject member order queries** ([firestore.rules:L89-91](file:///e:/pitchaya_project/Mypos/firestore.rules#L89-L91))
   - **What this is:** Security rule granting members read access to their own orders.
   - **Problem:** Firestore rules do not filter results; queries without explicit `.where('createdBy', '==', auth.uid)` are rejected with `PERMISSION_DENIED` by the rules engine.
   - **Fix:** Require client queries for members to filter by `createdBy`, or split member personal orders into subcollections.
   - **If we skip it:** Members cannot view their order history once connected to live Firestore.

5. **Cloud Functions lockdown blocks shop setup on free Spark plan** ([firestore.rules:L24-37](file:///e:/pitchaya_project/Mypos/firestore.rules#L24-L37))
   - **What this is:** Server-side rules that disallow client writes on `shops`, `members`, and `memberships`.
   - **Problem:** On Firebase Spark (free), Cloud Functions cannot run. Clients cannot create a shop or join without upgrading to Blaze.
   - **Fix:** Allow client creation of a shop if `request.auth.uid == request.resource.data.ownerUid` during local development and MVP.
   - **If we skip it:** The app cannot initialize a new shop on Firebase without an active billing account.

---

### Should fix

6. **Manual stock adjust clamps negative stock to zero** ([lib/providers/pos_provider.dart:L532-536](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L532-L536))
   - **What this is:** Manual stock adjustment handler in settings/inventory.
   - **Problem:** It forces `stock: newStock > 0 ? newStock : 0`, which contradicts the v1.7 spec that allows negative stock.
   - **Fix:** Remove the clamp to allow `newStock` to be negative.
   - **If we skip it:** Reconciling oversold stock to an actual negative count fails.

7. **Creating a shop does not create an owner member** ([lib/providers/pos_provider.dart:L654-669](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L654-L669), [lib/repositories/repositories.dart:L153-162](file:///e:/pitchaya_project/Mypos/lib/repositories/repositories.dart#L153-L162))
   - **What this is:** Initial shop creation logic.
   - **Problem:** It creates a `Shop` entity but adds no `Member` record with `role: owner` to `membersBox`.
   - **Fix:** Insert a default `Member(role: MemberRole.owner)` for `ownerUserId` inside `createShop`.
   - **If we skip it:** Member lists remain empty, and permissions fall back to unsafe defaults.

8. **Proportional discount becomes stale when cart quantity changes** ([lib/providers/pos_provider.dart:L308-321](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L308-L321))
   - **What this is:** Updating item quantity or removing items from the active cart.
   - **Problem:** Changing quantities does not re-run proportional discount allocation. Discarded items take their discount portion with them, shrinking total bill discount silently.
   - **Fix:** Store the raw bill discount percentage or target amount on `PosProvider` and re-evaluate `applyWholeBillDiscount` whenever cart lines change.
   - **If we skip it:** Changing a cart quantity results in incorrect discount proportions across artists.

9. **PosProvider duplicates business logic instead of using Repository layer** ([lib/providers/pos_provider.dart:L7](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L7))
   - **What this is:** State management layer communicating with persistence.
   - **Problem:** `PosProvider` talks directly to `DatabaseService` (Hive), bypassing the clean repository contracts created in `lib/repositories/repositories.dart`.
   - **Fix:** Inject repository interfaces into `PosProvider`.
   - **If we skip it:** Migrating from Hive to live Firestore requires rewriting `PosProvider` a second time.

10. **Order items contain empty order ID** ([lib/providers/pos_provider.dart:L413-422](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L413-L422))
    - **What this is:** Generating order item models prior to creating an order.
    - **Problem:** `OrderItem.orderId` is hardcoded to `''` and never backfilled with `order.id`.
    - **Fix:** Assign `orderId: order.id` when attaching items to the order.
    - **If we skip it:** Filtering or exporting standalone order items loses traceability to their parent order.

---

### Nice to have

11. **Duplicated settlement computation math** ([lib/providers/pos_provider.dart:L607-639](file:///e:/pitchaya_project/Mypos/lib/providers/pos_provider.dart#L607-L639) vs [lib/repositories/repositories.dart:L426-452](file:///e:/pitchaya_project/Mypos/lib/repositories/repositories.dart#L426-L452))
    - **What this is:** Calculating artist payouts, commissions, and gross totals.
    - **Problem:** `computeSettlementForEvent` and `SettlementRepository.computeForEvent` calculate the same metrics with slight differences (`artistTotals` vs loop sum).
    - **Fix:** Centralize settlement calculation in `SettlementRepository`.
    - **If we skip it:** Any formula update must be edited in two separate files.

---

Verdict: Healthy architecture, but fix the cost leak (#1) and cross-shop category deletion (#2) before multi-user booth use.  
Lean: -120 lines possible by wiring `PosProvider` directly to `repositories.dart`.  
Not checked: Web landing page JavaScript (`js/`) and live Firebase backend connectivity.