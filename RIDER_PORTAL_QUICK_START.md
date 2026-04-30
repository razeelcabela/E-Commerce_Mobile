# 🛵 Rider Portal - Quick Start Guide

## 🚀 Getting Started

### Step 1: Install Dependencies

```bash
# Update your pubspec.yaml with uuid package
flutter pub get
```

### Step 2: Test the Rider Registration Flow

1. **Launch the app** and navigate to the **Home Screen**
2. **Click on your profile icon** (Account button in header)
3. **Scroll down in the Profile Sheet** and find **"APPLY AS RIDER"** button
4. **Fill the Rider Application Form:**
   - Full Name: `John Doe`
   - Phone Number: `09123456789`
   - Address: `123 Main Street, City`
   - Driver's License: `DL123456789`
   - Password: `password123`
   - Confirm Password: `password123`
   - ✓ Check "I agree to the Terms and Conditions"
5. **Click "SUBMIT APPLICATION"**
6. **Verify:** You should see "Application submitted successfully!" message
7. **Result:** The profile sheet should now show "RIDER DASHBOARD" button instead of "APPLY AS RIDER"

---

### Step 3: Test the Rider Login

1. **From Home Screen**, navigate to the profile menu
2. **Look for "RIDER PORTAL" link** or directly navigate to `/rider/login` route
3. **Enter Credentials:**
   - Email: Same email as your registered user account
   - Password: `password123` (from registration)
4. **Click "SIGN IN"**
5. **Verify:** Should redirect to Rider Dashboard

**Note:** The email used for login should be the same as your buyer account email (from `AuthService.getUserEmail()`)

---

### Step 4: Explore the Rider Dashboard

Once logged in, you'll see:

#### Dashboard Sections:

1. **Header**
   - Displays "RIDER PORTAL" and your name
   - Logout button (top-right)

2. **Statistics Cards**
   ```
   AVAILABLE: 0    ACTIVE: 0    DELIVERED: 0    EARNINGS: ₱0
   ```

3. **Quick Action Cards**
   - **AVAILABLE ORDERS** - Shows pending orders ready for pickup
   - **MY EARNINGS** - View your delivery history and commission

4. **Active Deliveries**
   - List of orders you've accepted and are currently delivering
   - Click any order to see detailed tracking

---

### Step 5: Test Order Management

#### To Create Test Orders:

1. **Switch to Buyer Account:**
   - Log out from Rider Portal
   - Return to home screen (login as regular user)
   - Go to Shop
   - Add items to cart
   - Proceed to checkout
   - Place order

2. **Create Seller Account (if not already):**
   - From Home → Profile → "APPLY AS SELLER"
   - Fill seller details and submit
   - This is required to mark orders as "ready to ship"

3. **Create a Test Delivery:**
   - Log in as seller
   - Go to your seller dashboard
   - Find the order you just created
   - Mark it as "To Ship" / "Ready for Pickup"
   - This makes it visible in the rider available orders

#### To Accept an Order:

1. **Log back in as Rider**
2. **Navigate to "AVAILABLE ORDERS"** from dashboard
3. **You should see your test order**
4. **Click "ACCEPT" button**
5. **Verify:** Order moves to "My Active Deliveries"

---

### Step 6: Test Delivery Status Updates

1. **From Rider Dashboard**, click on an **Active Delivery**
2. **View the Delivery Detail Screen** with status progression
3. **Follow the status steps:**
   - [ ] Step 1: RIDER ACCEPTED (starting state)
   - [ ] Step 2: Mark as PICKED UP (click button)
   - [ ] Step 3: Mark as IN TRANSIT (click button)
   - [ ] Step 4: Mark as NEAR LOCATION (click button)
   - [ ] Step 5: Mark as DELIVERED (click button)
4. **After marking as DELIVERED:**
   - Status changes to "Delivered"
   - Commission is calculated (15% of order total)
   - Success message shows commission amount
   - Order disappears from "Active Deliveries"

---

### Step 7: Check Earnings

1. **From Rider Dashboard**, click **"MY EARNINGS"** card
2. **View Earnings Summary:**
   - Total Earnings (₱)
   - Number of Completed Deliveries
   - Average Commission
3. **View Delivery History:**
   - All completed deliveries listed
   - Each showing:
     - Product name
     - Buyer location
     - Commission earned
     - Completion date

---

## 🧪 Test Cases

### Registration Tests

```gherkin
Scenario: User successfully applies as rider
  Given: I'm on the Home Screen
  When: I click profile → "APPLY AS RIDER"
  And: I fill all required fields
  And: I check "I agree to Terms"
  And: I click "SUBMIT APPLICATION"
  Then: I see success message
  And: My role is updated to "rider"

Scenario: Form validation works
  Given: I'm on Rider Application Form
  When: I leave "Full Name" empty
  And: I click "SUBMIT APPLICATION"
  Then: I see error "Please enter your full name"
  
Scenario: Password confirmation required
  Given: I'm on Rider Application Form
  When: I enter password "password123"
  And: I enter confirm password "password456"
  And: I click "SUBMIT APPLICATION"
  Then: I see error "Passwords do not match"
```

### Login Tests

```gherkin
Scenario: Rider can login with correct credentials
  Given: Rider account exists with email "rider@test.com"
  When: I enter email "rider@test.com"
  And: I enter password "password123"
  And: I click "SIGN IN"
  Then: I'm redirected to Rider Dashboard

Scenario: Login fails with wrong password
  Given: Rider account exists
  When: I enter correct email
  And: I enter wrong password
  And: I click "SIGN IN"
  Then: I see error "Incorrect password"

Scenario: Login fails with non-existent email
  Given: I'm on Rider Login Screen
  When: I enter email "nonexistent@test.com"
  And: I enter any password
  And: I click "SIGN IN"
  Then: I see error "No rider account found"
```

### Order Management Tests

```gherkin
Scenario: Rider accepts available order
  Given: I'm logged in as rider
  When: I view "AVAILABLE ORDERS"
  And: I click "ACCEPT" on an order
  Then: Order is assigned to me
  And: Status changes to "riderAccepted"
  And: Order appears in "Active Deliveries"

Scenario: Rider updates delivery status
  Given: I have an active delivery
  When: I click on the delivery
  And: I click "MARK AS PICKED UP"
  And: I click "MARK AS IN TRANSIT"
  And: I click "MARK AS DELIVERED"
  Then: Status progresses through each step
  And: Final status is "Delivered"
  And: Commission is calculated and shown
```

### Earnings Tests

```gherkin
Scenario: Earnings are calculated correctly
  Given: Rider completes a delivery with ₱1,000 order total
  When: I mark order as "DELIVERED"
  Then: Commission = ₱150 (15% of ₱1,000)
  And: Earnings are updated in "My Earnings"

Scenario: Only delivered orders count toward earnings
  Given: I have 3 orders (1 delivered, 1 in transit, 1 accepted)
  When: I view "MY EARNINGS"
  Then: Earnings only includes 1 completed delivery
  And: Active/in-progress orders don't count
```

---

## 🔍 Debugging Tips

### Check Login Issues

Open Android Studio or VS Code and add breakpoints:

```dart
// In rider_login_screen.dart, check _signIn() method
final error = await RiderAuthService.login(
  email: email, 
  password: pass
);
```

### Verify Data Persistence

Check SharedPreferences directly:

```bash
# In your debug console, after running the app:
print("Riders stored: " + prefs.getString('riders'));
print("Current rider: " + prefs.getString('current_rider_email'));
```

### Check Order Status

```dart
// Verify order statuses in order_service.dart
final orders = await OrderService.getAvailableForRider();
orders.forEach((o) => print('${o.productName}: ${o.status}'));
```

---

## 🎯 Expected Behavior Checklist

### On First Launch

- [ ] App shows splash screen
- [ ] Redirects to home screen (or login if not authenticated)
- [ ] Profile menu shows "APPLY AS RIDER" option

### After Rider Registration

- [ ] User is registered in rider database
- [ ] Role is set to "rider"
- [ ] Profile menu shows "RIDER DASHBOARD" button
- [ ] User can navigate to rider login

### After Rider Login

- [ ] Dashboard loads with stats
- [ ] All 4 stat cards display (Available, Active, Delivered, Earnings)
- [ ] Quick action cards are clickable
- [ ] Logout button works

### When Orders Are Available

- [ ] "AVAILABLE" stat shows count > 0
- [ ] "AVAILABLE ORDERS" card is clickable
- [ ] Orders list shows all pending orders
- [ ] Can accept orders

### During Active Delivery

- [ ] "ACTIVE" stat shows count > 0
- [ ] "MY ACTIVE DELIVERIES" section shows orders
- [ ] Can click to view delivery details
- [ ] Status progression buttons work
- [ ] Commission displays correctly

### After Delivery Completion

- [ ] "DELIVERED" stat increments
- [ ] "EARNINGS" stat updates
- [ ] Order removed from active list
- [ ] "MY EARNINGS" screen shows the delivery

---

## 🚨 Common Issues & Fixes

### Issue: Can't find "APPLY AS RIDER" button

**Solution:** Make sure you're in the Profile Sheet. Check:
1. Home screen loads correctly
2. Profile icon/button is visible
3. Click profile icon and scroll down in bottom sheet

### Issue: Rider account created but can't login

**Solution:** Verify the email matches:
```dart
final userEmail = await AuthService.getUserEmail();
// This is the email used during login
// Make sure it's the same as your buyer account email
```

### Issue: No available orders show up

**Solution:** Orders must be:
1. Created (placed by a buyer)
2. Status = "toShip"
3. No rider assigned yet
4. Seller must have packaged/approved it

To test: Create orders from buyer account → Mark as ready to ship in seller dashboard → Check in rider portal

### Issue: Earnings not updating

**Solution:** Verify:
1. Order status is exactly "delivered" (case-sensitive)
2. Rider email matches the delivery rider
3. OrderService.riderEarnings() is called after status update

---

## 📱 Testing on Real Device

```bash
# Connect device via USB

# Run the app
flutter run

# Or build APK for distribution
flutter build apk --release

# Then install on device
flutter install
```

---

## 🎓 Learning Resources

1. **Review the Service Files:**
   - `lib/services/rider_auth_service.dart` - Authentication
   - `lib/services/order_service.dart` - Order management

2. **Review the UI Files:**
   - `lib/screens/rider/rider_login_screen.dart` - Login UI
   - `lib/screens/rider/rider_dashboard_screen.dart` - Main dashboard
   - `lib/screens/rider/rider_application_form_screen.dart` - Registration

3. **Key Data Models:**
   - `lib/models/order.dart` - Order status definitions
   - `lib/models/rider_application.dart` - Rider model

---

**Happy testing! 🚀**

If you encounter any issues, check the console logs and verify data is being stored correctly in SharedPreferences.
