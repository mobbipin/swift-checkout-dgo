import XCTest

/// End-to-end walkthroughs of the checkout. Each step saves a screenshot to
/// `$SCREENSHOT_DIR` (pass `TEST_RUNNER_SCREENSHOT_DIR=...` to xcodebuild) and attaches it to the result bundle.
final class CheckoutFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
    }

    // MARK: Helpers

    private func snap(_ name: String) {
        // Let screen transitions (0.28s) finish so captures aren't mid-fade.
        Thread.sleep(forTimeInterval: 0.5)
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    private func button(_ id: String) -> XCUIElement { app.buttons[id].firstMatch }
    private func text(_ id: String) -> XCUIElement { app.staticTexts[id].firstMatch }

    private func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let el = button(id)
        XCTAssertTrue(el.waitForExistence(timeout: 5), "missing button \(id)", file: file, line: line)
        el.tap()
    }

    private func assertText(_ id: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let el = text(id)
        XCTAssertTrue(el.waitForExistence(timeout: 5), "missing text \(id)", file: file, line: line)
        XCTAssertEqual(el.label, expected, file: file, line: line)
    }

    private func assertVisible(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts[label].firstMatch.waitForExistence(timeout: 5), "missing \"\(label)\"", file: file, line: line)
    }

    private func dev(_ chip: String) {
        if !button("dev_\(chip)").exists { tap("devHandle") }
        tap("dev_\(chip)")
    }

    private func type(_ id: String, _ value: String) {
        let field = app.textFields[id]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "missing field \(id)")
        field.tap()
        field.typeText(value)
    }

    private func dismissKeyboard() {
        if app.keyboards.count > 0 { text("payTitle").tap() }
    }

    private func openPlansFromHome() {
        let cta = button("driveSeePlans")
        XCTAssertTrue(cta.waitForExistence(timeout: 5))
        // The card sits under the bottom nav at launch; scroll it into the clear first.
        var tries = 0
        while cta.frame.maxY > app.frame.height * 0.7 && tries < 3 {
            app.scrollViews["landingScroll"].swipeUp(velocity: .slow)
            tries += 1
        }
        cta.tap()
        assertText("headerTitle", "Choose a plan")
    }

    private func goHomeFromConfirmation() {
        tap("goHome")
        XCTAssertTrue(button("nav_Home").waitForExistence(timeout: 5))
    }

    private func openAccount() {
        tap("nav_Account")
        XCTAssertTrue(text("accountBadge").waitForExistence(timeout: 5))
    }

    // MARK: Landing

    func test01_LandingTabsSearchAndDetail() {
        snap("01-home-hero")
        app.scrollViews["landingScroll"].swipeUp()
        snap("02-home-subscribe-drive")
        app.scrollViews["landingScroll"].swipeUp()
        snap("03-home-rails")

        for tab in ["hotstar", "osr", "sports", "entertainment", "specials", "junior"] {
            let chip = button("tab_\(tab)")
            if chip.frame.maxX > app.frame.width { app.scrollViews["tabStrip"].swipeLeft() }
            chip.tap()
            snap("04-tab-\(tab)")
        }
        app.scrollViews["tabStrip"].swipeRight()
        tap("tab_hotstar")
        app.scrollViews["landingScroll"].swipeUp()
        tap("poster_Asur 2")
        assertText("detailTitle", "Asur 2")
        snap("05-detail-sheet")
        tap("detailClose")

        tap("nav_Search")
        type("searchField", "asur")
        XCTAssertTrue(button("result_Asur").waitForExistence(timeout: 3))
        XCTAssertTrue(button("result_Asur 2").exists)
        snap("06-search-results")
        tap("result_Asur")
        assertText("detailTitle", "Asur")
        tap("detailCta")
        assertText("headerTitle", "Choose a plan")
        snap("07-detail-to-plans")
    }

    // MARK: Nepal (NPR wallets, one-time)

    func test02_NepalKhaltiPurchaseWithCoupon() {
        openPlansFromHome()
        assertText("billedIn", "Billed in NPR")
        assertText("tierPrice_PLUS", "रू 799")
        assertText("summaryPrice", "3 months · रू 799")
        snap("10-np-plans-plus-3m")

        tap("duration_M12")
        assertText("tierPrice_PLUS", "रू 2,699")
        snap("11-np-plans-plus-12m")

        tap("duration_M01")
        assertVisible("No live sports")
        tap("pagerDot_MOBILE")
        assertText("summaryName", "DGO Mobile")
        assertText("tierPrice_MOBILE", "रू 199")
        snap("12-np-plans-mobile-1m")

        tap("pagerDot_PLUS")
        tap("duration_M03")
        assertText("summaryName", "DGO Plus")
        tap("planContinue")
        assertText("headerTitle", "Payment")
        XCTAssertFalse(button("payButton").isEnabled)
        snap("13-np-payment")

        type("couponInput", "BAD")
        tap("couponApply")
        assertText("couponError", "That code isn’t valid.")
        app.textFields["couponInput"].clearText()
        app.textFields["couponInput"].typeText("DGO10")
        tap("couponApply")
        assertText("couponApplied", "DGO10 · 10% off")
        assertText("dueToday", "रू 719")
        dismissKeyboard()
        snap("14-np-coupon-applied")

        // Wallets hand off to the provider app; no phone number is collected here.
        tap("psp_khalti")
        XCTAssertFalse(app.textFields["walletInput"].exists)
        XCTAssertTrue(button("payButton").isEnabled)
        snap("15-np-khalti-selected")
        tap("payButton")

        assertText("confirmTitle", "You're in")
        assertText("confirmDetail", "DGO Plus · 3 months")
        assertText("confirm_Paid today", "रू 719")
        assertText("confirm_Payment", "Khalti by IME")
        assertText("confirm_Access", "3 months of access")
        snap("17-np-confirmation")

        goHomeFromConfirmation()
        assertText("drivePlanName", "DGO Plus")
        snap("18-np-subscribed-home")
    }

    func test03_NepalGetPayCardDeclineThenSuccess() {
        openPlansFromHome()
        tap("pagerDot_MOBILE")
        tap("duration_M01")
        tap("planContinue")
        tap("psp_getpay")
        type("cardNumber", "4000000000000002")
        type("cardExpiry", "1230")
        type("cardCvc", "123")
        type("cardName", "Test User")
        XCTAssertEqual(app.textFields["cardNumber"].value as? String, "4000 0000 0000 0002")
        XCTAssertEqual(app.textFields["cardExpiry"].value as? String, "12/30")
        dismissKeyboard()
        tap("payButton")
        assertText("paymentError", "Card declined. Try another.")
        snap("20-np-getpay-declined")

        app.textFields["cardNumber"].clearText()
        app.textFields["cardNumber"].typeText("4242424242424242")
        dismissKeyboard()
        tap("payButton")
        assertText("confirmTitle", "You're in")
        assertText("confirm_Paid today", "रू 199")
        assertText("confirm_Payment", "GetPay")
        snap("21-np-getpay-confirmation")
    }

    func test04_NepalPrepaidManage_RenewDeferUpgrade() {
        // Buy Mobile 3M with eSewa.
        openPlansFromHome()
        tap("pagerDot_MOBILE")
        tap("planContinue")
        tap("psp_esewa")
        tap("payButton")
        assertText("confirmTitle", "You're in")
        goHomeFromConfirmation()

        openAccount()
        assertText("accountBadge", "ACTIVE")
        assertText("activePlan", "DGO Mobile · 3 months")
        snap("30-np-account-prepaid")

        tap("accountAddTime")
        assertText("headerTitle", "Change plan")
        assertText("planHeadline", "Change your plan")
        // Plus on the same term is a fixed-tier upgrade for the difference.
        tap("pagerDot_PLUS")
        assertText("tierState_PLUS", "Upgrade")
        assertText("tierPrice_PLUS", "रू 250")
        XCTAssertEqual(button("planContinue").label, "Upgrade")
        snap("31-np-manage-fixed-upgrade")

        // Shorter term is deferred and blocked.
        tap("pagerDot_MOBILE")
        tap("duration_M01")
        XCTAssertFalse(button("planContinue").isEnabled)
        XCTAssertEqual(button("planContinue").label, "After this term")
        snap("32-np-manage-deferred")

        // Same plan = renewal.
        tap("duration_M03")
        XCTAssertEqual(button("planContinue").label, "Add time")
        snap("33-np-manage-renewal")

        tap("pagerDot_PLUS")
        tap("planContinue")
        assertText("dueToday", "रू 250")
        tap("psp_fonepay")
        tap("payButton")
        assertText("confirmTitle", "Plan updated")
        assertText("confirm_Access", "Access date unchanged")
        snap("34-np-upgrade-confirmation")
        goHomeFromConfirmation()

        // Longer term = immediate extension.
        tap("driveManage")
        tap("duration_M12")
        assertText("tierState_PLUS", "Longer term")
        XCTAssertEqual(button("planContinue").label, "Add time")
        tap("planContinue")
        tap("psp_connectips")
        tap("payButton")
        assertText("confirmTitle", "Time added")
        assertText("confirm_Access", "12 months added after this term")
        snap("35-np-extension-confirmation")
    }

    // MARK: International (USD Stripe, recurring)

    func test05_StripeZoneBPurchaseWithPromo() {
        dev("ZB")
        snap("40-dev-toggle-zb")
        openPlansFromHome()
        assertText("billedIn", "Billed in USD")
        assertText("tierPrice_PLUS", "$29.99")
        assertText("summaryPrice", "3 months · $29.99")
        snap("41-zb-plans-plus-3m")

        tap("duration_M12")
        assertText("tierPrice_PLUS", "$99.99")
        tap("duration_M03")
        tap("planContinue")
        assertText("dueToday", "$29.99")
        assertVisible("Billed every 3 months")
        assertVisible("You’ll finish on Stripe’s secure page.")
        snap("42-zb-stripe-payment")

        type("couponInput", "DGO20")
        tap("couponApply")
        assertText("dueToday", "$23.99")
        dismissKeyboard()
        XCTAssertEqual(button("stripeButton").label, "Continue to Stripe · $23.99")
        snap("43-zb-stripe-promo")

        tap("stripeButton")
        assertText("confirmTitle", "You're in")
        assertText("confirm_Payment", "Stripe Checkout")
        assertText("confirm_Schedule", "Billed every 3 months")
        snap("44-zb-confirmation")
    }

    func test06_StripeManage_DowngradeUpgradeCancelResume() {
        dev("ZB")
        dev("SUB")
        openAccount()
        assertText("activePlan", "DGO Plus · 3 months")
        assertText("renewalState", "Auto-renewal on")
        snap("50-zb-account-recurring")

        tap("outline_Manage plan")
        assertText("tierState_PLUS", "Current")
        XCTAssertFalse(button("planContinue").isEnabled)
        assertText("summaryPrice", "3 months · Current plan")
        snap("51-zb-manage-current")

        tap("pagerDot_MOBILE")
        assertText("tierState_MOBILE", "Downgrade")
        XCTAssertEqual(button("planContinue").label, "Schedule downgrade")
        snap("52-zb-manage-downgrade")
        tap("planContinue")
        assertText("dueToday", "No charge today")
        XCTAssertEqual(button("stripeButton").label, "Schedule on Stripe")
        snap("53-zb-downgrade-payment")
        tap("stripeButton")
        assertText("confirmTitle", "Plan change scheduled")
        snap("54-zb-downgrade-confirmation")
        goHomeFromConfirmation()

        openAccount()
        XCTAssertTrue(text("pendingPlan").waitForExistence(timeout: 5))
        XCTAssertTrue(text("pendingPlan").label.hasPrefix("Changes to DGO Mobile · 3 months on "))
        snap("55-zb-account-pending-downgrade")

        // Upgrade to Plus 12M: starts now, clears the pending downgrade.
        tap("outline_Manage plan")
        tap("pagerDot_PLUS")
        tap("duration_M12")
        assertText("tierState_PLUS", "Upgrade")
        tap("planContinue")
        assertText("dueToday", "Price difference")
        assertText("payLifecycleNote", "Starts now. A new billing period begins today, minus credit for unused time. Stripe shows the exact amount.")
        snap("56-zb-upgrade-payment")
        tap("stripeButton")
        assertText("confirmTitle", "Plan updated")
        XCTAssertTrue(text("confirm_Schedule").label.hasPrefix("Next bill "))
        snap("57-zb-upgrade-confirmation")
        goHomeFromConfirmation()

        openAccount()
        assertText("activePlan", "DGO Plus · 12 months")
        XCTAssertFalse(text("pendingPlan").exists)

        // Cancel renewal: 3 steps.
        tap("outline_Cancel renewal")
        assertText("cancelStep", "Step 1 of 3")
        snap("58-zb-cancel-step1")
        tap("cancelNext")
        assertText("cancelStep", "Step 2 of 3")
        XCTAssertFalse(button("cancelNext").isEnabled)
        tap("reason_Too expensive")
        snap("59-zb-cancel-step2")
        tap("cancelNext")
        assertText("cancelStep", "Step 3 of 3")
        XCTAssertFalse(button("cancelNext").isEnabled)
        type("cancelPhrase", "cancel")
        XCTAssertEqual(app.textFields["cancelPhrase"].value as? String, "CANCEL")
        snap("60-zb-cancel-step3")
        tap("cancelNext")
        assertText("planStatus", "ENDS SOON")
        assertText("renewalState", "Cancellation scheduled")
        snap("61-zb-cancelled")

        tap("resumeRenewal")
        snap("62-zb-resume-confirm")
        tap("resumeConfirm")
        assertText("planStatus", "ACTIVE")
        assertText("renewalState", "Auto-renewal on")
        snap("63-zb-resumed")
    }

    func test07_ZonesAAndCPricing() {
        dev("ZA")
        openPlansFromHome()
        assertText("tierPrice_PLUS", "$14.99")
        tap("duration_M12")
        assertText("tierPrice_PLUS", "$50.99")
        snap("70-za-plans-12m")
        tap("headerBack")

        dev("ZC")
        openPlansFromHome()
        // The chosen duration carries over between checkouts (same as the Kotlin app).
        tap("duration_M03")
        assertText("tierPrice_PLUS", "$17.99")
        tap("pagerDot_MOBILE")
        tap("duration_M01")
        assertText("tierPrice_MOBILE", "$4.99")
        snap("71-zc-plans-mobile-1m")
    }

    // MARK: Account

    func test08_AccountGuestMenuAndSignOut() {
        openAccount()
        assertText("accountBadge", "GUEST")
        assertVisible("No active plans on this account")
        tap("menu_About")
        assertText("accountNotice", "DGO checkout prototype · entitlement spec v3.0.")
        snap("80-account-guest")

        tap("subscribeNow")
        assertText("headerTitle", "Choose a plan")
        tap("headerBack")

        dev("SUB")
        openAccount()
        assertText("accountBadge", "ACTIVE")
        assertText("activePlan", "DGO Plus · 3 months")
        snap("81-account-np-subscribed")
        tap("signOut")
        XCTAssertTrue(button("driveSeePlans").waitForExistence(timeout: 5))
        openAccount()
        assertText("accountBadge", "GUEST")
    }

    func test10_StripeSameIntervalUpgradeKeepsBillingDate() {
        // Buy ZA Mobile 3M, then upgrade to Plus 3M: same interval, billing date unchanged.
        dev("ZA")
        openPlansFromHome()
        tap("pagerDot_MOBILE")
        tap("duration_M03")
        assertText("tierPrice_MOBILE", "$9.99")
        tap("planContinue")
        tap("stripeButton")
        assertText("confirmTitle", "You're in")
        goHomeFromConfirmation()

        openAccount()
        let billDate = text("planDate").label
        XCTAssertTrue(billDate.hasPrefix("Next bill "))
        tap("outline_Manage plan")
        tap("pagerDot_PLUS")
        assertText("tierState_PLUS", "Upgrade")
        tap("planContinue")
        XCTAssertTrue(text("payLifecycleNote").label.hasPrefix("Starts now. You pay only for the days left until "))
        snap("64-za-same-interval-upgrade-payment")
        tap("stripeButton")
        assertText("confirmTitle", "Plan updated")
        assertText("confirm_Schedule", billDate)
        snap("65-za-same-interval-upgrade-confirmation")
        goHomeFromConfirmation()

        openAccount()
        assertText("activePlan", "DGO Plus · 3 months")
        assertText("planDate", billDate)
    }

    // MARK: Exclusive (one-time event passes)

    func test11_NepalEventPassWithoutPlan() {
        openPlansFromHome()
        tap("catalogTab_Exclusive")
        assertText("headerTitle", "Exclusive")
        assertText("eventPrice_EURO28-ALL", "रू 999")
        assertText("summaryPrice", "Full tournament pass · रू 999")
        XCTAssertEqual(button("planContinue").label, "Buy pass")
        snap("100-np-exclusive-full-pass")

        tap("eventDot_EURO28-KO")
        assertText("summaryPrice", "Knockout stage pass · रू 499")
        snap("101-np-exclusive-knockout-pass")

        tap("eventDot_EURO28-ALL")
        assertText("summaryPrice", "Full tournament pass · रू 999")
        tap("planContinue")
        assertText("headerTitle", "Payment")
        assertText("payTitle", "EURO 2028 · Full tournament pass")
        tap("psp_khalti")
        snap("102-np-exclusive-payment")
        tap("payButton")

        assertText("confirmTitle", "Pass unlocked")
        assertText("confirmDetail", "EURO 2028 · Full tournament pass")
        assertText("confirm_Paid today", "रू 999")
        XCTAssertTrue(text("confirm_Access").label.hasSuffix("· no renewal"))
        snap("103-np-exclusive-confirmation")
        goHomeFromConfirmation()

        openAccount()
        assertText("accountBadge", "GUEST")
        assertText("pass_EURO28-ALL", "EURO 2028 · Full tournament pass")
        XCTAssertFalse(app.staticTexts["No active plans on this account"].exists)
        snap("104-np-account-pass")

        tap("browseExclusive")
        assertText("headerTitle", "Exclusive")
        XCTAssertEqual(button("planContinue").label, "Owned")
        XCTAssertFalse(button("planContinue").isEnabled)
        snap("105-np-exclusive-owned")
        tap("eventDot_EURO28-KO")
        XCTAssertEqual(button("planContinue").label, "Included")
        XCTAssertFalse(button("planContinue").isEnabled)
        snap("106-np-exclusive-included")
    }

    func test12_StripeEventPassAlongsidePlan() {
        dev("ZB")
        dev("SUB")
        openAccount()
        tap("browseExclusive")
        assertText("eventPrice_EURO28-ALL", "$24.99")
        tap("eventDot_EURO28-KO")
        assertText("summaryPrice", "Knockout stage pass · $14.99")
        snap("110-zb-exclusive-catalog")
        tap("planContinue")
        assertText("dueToday", "$14.99")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "One-time pass · until")).firstMatch.exists)
        snap("111-zb-exclusive-stripe-payment")
        tap("stripeButton")
        assertText("confirmTitle", "Pass unlocked")
        assertText("confirm_Payment", "Stripe Checkout")
        snap("112-zb-exclusive-confirmation")
        goHomeFromConfirmation()

        openAccount()
        assertText("activePlan", "DGO Plus · 3 months")
        assertText("pass_EURO28-KO", "EURO 2028 · Knockout stage pass")
        snap("113-zb-account-plan-and-pass")
    }

    func test13_DevToggleTurnsExclusiveOff() {
        tap("devHandle")
        snap("120-dev-toggle-ppv")
        tap("dev_PPV")
        openPlansFromHome()
        XCTAssertFalse(button("catalogTab_Exclusive").exists)
        snap("121-ppv-off-plans-only")
        tap("headerBack")
        openAccount()
        XCTAssertFalse(button("browseExclusive").exists)
    }

    func test09_ConfirmationAutoReturnsHome() {
        dev("ZC")
        openPlansFromHome()
        tap("planContinue")
        tap("stripeButton")
        assertText("confirmTitle", "You're in")
        // Countdown sends the user home after 10s.
        XCTAssertTrue(button("driveManage").waitForExistence(timeout: 14))
        snap("90-auto-home-after-countdown")
    }
}

extension XCUIElement {
    func clearText() {
        guard let current = value as? String, !current.isEmpty else { return }
        tap()
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
    }
}
