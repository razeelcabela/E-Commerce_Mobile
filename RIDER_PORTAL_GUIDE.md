# 🛵 Rider Portal System Documentation

## Overview

The Rider Portal is a complete delivery management system built into the Varón e-commerce platform. It allows registered riders to access delivery orders, manage active deliveries, track earnings, and update delivery status in real-time.

---

## 📱 System Architecture

### User Flows

```
┌─────────────────┐
│   Home Screen   │
│  (Buyer View)   │
└────────┬────────┘
         │
         ├─→ Profile Sheet
         │    │
         │    └─→ "APPLY AS RIDER" Button
         │        │
         │        └─→ Rider Application Form Screen
         │            │
         │            └─→ Register as Rider (RiderAuthService)
         │                └─→ Set Role: "rider"
         │
         └─→ Home Navigation
              │
              └─→ "RIDER PORTAL" Link
                  │
                  └─→ Rider Login Screen (/rider/login)
                      │
                      ├─→ Email + Password
                      ├─→ RiderAuthService.login()
                      │
                      └─→ Rider Dashboard (/rider/dashboard)
                          │
                          ├─→ Stats & Overview
                          ├─→ Available Orders
                          ├─→ Active Deliveries
                          └─→ My Earnings
```

---

## 🔐 Authentication Flow

### 1. **Rider Registration** (From Home Screen Profile)

**Screen:** `RiderApplicationFormScreen`
**Location:** `lib/screens/rider/rider_application_form_screen.dart`

**Fields Required:**
- Full Name
- Phone Number
- Address
- Driver's License Number
- Password (min 6 characters)
- Confirm Password
- Accept Terms & Conditions

**Process:**
1. User fills the application form
2. Form validates all required fields
3. `RiderAuthService.register()` creates the rider account in SharedPreferences
4. `RiderApplicationService.syncRole()` sets the user role to "rider"
5. Success confirmation shown
6. User is returned to profile sheet

**Service Used:**
```dart
RiderAuthService.register({
  email: userEmail,
  password: password,
  fullName: fullName,
  phoneNumber: phoneNumber,
  address: address,
  driversLicense: driversLicense,
})
```

---

### 2. **Rider Login** (Dedicated Portal)

**Screen:** `RiderLoginScreen`
**Location:** `lib/screens/rider/rider_login_screen.dart`
**Route:** `/rider/login`

**Login Process:**
1. Navigate to `/rider/login`
2. Enter email and password
3. System calls `RiderAuthService.login()`
4. Validates against rider database
5. On success → redirects to `/rider/dashboard`
6. On failure → shows error message

**Authentication Logic:**
```dart
Future<String?> login({
  required String email,
  required String password,
}) async {
  final rider = await _getRider(email);
  if (rider == null) return 'No rider account found for this email';
  if (rider['password'] != password) return 'Incorrect password';
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_currentRiderKey, email);
  return null; // Success
}
```

---

## 📦 Rider Dashboard

**Screen:** `RiderDashboardScreen`
**Location:** `lib/screens/rider/rider_dashboard_screen.dart`
**Route:** `/rider/dashboard`

### Dashboard Components

#### 1. **Header**
- Displays "RIDER PORTAL" label
- Shows rider's full name
- Logout button

#### 2. **Statistics Row** (4 Cards)
| Stat | Description |
|------|-------------|
| AVAILABLE | Orders ready to be picked up |
| ACTIVE | Deliveries currently in progress |
| DELIVERED | Total completed deliveries |
| EARNINGS | Total commission earned (₱) |

#### 3. **Quick Actions**
- **AVAILABLE ORDERS** - View and accept new orders
- **MY EARNINGS** - Check delivery history and earnings

#### 4. **Active Deliveries**
Shows real-time list of deliveries in progress:
- Product name
- Delivery address
- Current status (color-coded)
- Commission amount

---

## 🎯 Order Management

### Available Orders Screen

**Screen:** `RiderAvailableOrdersScreen`
**Location:** `lib/screens/rider/rider_available_orders_screen.dart`

**Features:**
- Shows all pending orders ready for pickup
- Display: Product name, buyer, delivery address, estimated distance
- Pull-to-refresh functionality
- Accept order button

**Accept Order:**
```dart
Future<void> acceptOrder(String orderId, String riderEmail) async {
  // Assigns order to rider
  // Sets status to "riderAccepted"
  // Order becomes visible in "My Active Deliveries"
}
```

---

### Delivery Status Flow

**Screen:** `RiderDeliveryDetailScreen`
**Location:** `lib/screens/rider/rider_delivery_detail_screen.dart`

**Status Progression (Step-by-Step):**

```
1. RIDER ACCEPTED ──→ Pick up the order from seller
                       ↓
2. PICKED UP ───────→ Head to delivery address
                       ↓
3. IN TRANSIT ──────→ On the way to buyer
                       ↓
4. NEAR LOCATION ───→ Near the delivery location
                       ↓
5. DELIVERED ───────→ ✓ Successfully delivered
```

**Each Step Shows:**
- Current status label
- Status description/instructions
- Next action button
- Order details (product, address, commission)
- Progress indicator

**On Delivery Complete:**
- Status updates to "delivered"
- Commission amount displayed
- Success confirmation shown

---

## 💰 Earnings System

**Screen:** `RiderEarningsScreen`
**Location:** `lib/screens/rider/rider_earnings_screen.dart`

### Earnings Calculation

**Commission Rate:** 15% of order total

```dart
double get commission => total * commissionRate; // 0.15
```

**Example:**
- Product: ₱1,000
- Commission: ₱150 (15%)

### Earnings Display

1. **Summary Card**
   - Total Earnings (all delivered orders)
   - Number of Completed Deliveries
   - Average Commission per Delivery

2. **Delivery History**
   - List of all completed deliveries
   - Product name
   - Buyer location
   - Commission amount
   - Completion date

---

## 🔄 Data Models

### Rider Data Structure

Stored in SharedPreferences (`riders` key):

```json
{
  "email": "rider@example.com",
  "password": "hashedpassword",
  "fullName": "John Doe",
  "phoneNumber": "09123456789",
  "address": "123 Main St",
  "driversLicense": "DL123456",
  "status": "active",
  "createdAt": "2024-04-27T10:30:00Z"
}
```

### Order Status

Rider-specific statuses in Order model:
```dart
static const String riderAccepted = 'riderAccepted';
static const String pickedUp = 'pickedUp';
static const String inTransit = 'inTransit';
static const String nearLocation = 'nearLocation';
static const String delivered = 'delivered';
```

---

## 🛠️ Services Used

### 1. **RiderAuthService**
- `register()` - Create rider account
- `login()` - Authenticate rider
- `logout()` - Sign out
- `getCurrentRiderEmail()` - Get logged-in rider
- `getProfile()` - Fetch rider details
- `getFullName()` - Get rider's full name

### 2. **RiderApplicationService**
- `getRole()` - Check user role
- `syncRole()` - Update user role after registration

### 3. **OrderService**
- `getAvailableForRider()` - Pending orders
- `acceptOrder()` - Assign order to rider
- `getActiveDeliveriesByRider()` - In-progress deliveries
- `riderCompletedCount()` - Total delivered
- `riderEarnings()` - Calculate earnings
- `updateStatus()` - Update delivery status

---

## 📍 Navigation Routes

Add these routes to `main.dart` in MaterialApp:

```dart
routes: {
  '/rider/login': (context) => const RiderLoginScreen(),
  '/rider/dashboard': (context) => const RiderDashboardScreen(),
}
```

**Navigation Flow:**
```
Home → Profile → Apply as Rider → RiderApplicationFormScreen
                                    ↓
                            (After registration)
                                    ↓
                    Rider Portal Login → /rider/login
                                    ↓
                    Rider Dashboard → /rider/dashboard
                                    ↓
                    Available Orders / Earnings / Active Deliveries
```

---

## 🎨 UI/UX Design

### Color Scheme
- **Primary:** `#0A0A0A` (Black) - Headers, buttons
- **Secondary:** `#1A1A2E` (Dark Navy) - Rider portal accent
- **Background:** `#F6F6F6` (Light gray)
- **Text:** `#0A0A0A` (Black), `#888888` (Gray)

### Status Colors
| Status | Color | Meaning |
|--------|-------|---------|
| Rider Accepted | Blue (#1565C0) | Order assigned |
| Picked Up | Purple (#6A1B9A) | In warehouse |
| In Transit | Orange (#E65100) | On the way |
| Near Location | Green (#2E7D32) | Arriving soon |
| Delivered | Green | Complete |

---

## 🔍 Testing Checklist

### Registration
- [ ] User can apply as rider from profile
- [ ] Form validates all required fields
- [ ] Password confirmation works
- [ ] Terms checkbox required
- [ ] Success message shown
- [ ] Role updated to "rider"

### Login
- [ ] Rider can login with email/password
- [ ] Invalid credentials show error
- [ ] Redirects to dashboard on success
- [ ] Logout works correctly

### Dashboard
- [ ] Stats load correctly
- [ ] Available orders count accurate
- [ ] Active deliveries list shows
- [ ] Pull-to-refresh works

### Order Management
- [ ] Can view available orders
- [ ] Can accept order
- [ ] Status updates work
- [ ] Earnings calculate correctly

### Earnings
- [ ] Only shows delivered orders
- [ ] Commission calculation correct (15%)
- [ ] History displays all completed deliveries
- [ ] Total earnings updates

---

## 🚀 Future Enhancements

1. **Location Tracking**
   - Real-time GPS tracking
   - Route optimization
   - Estimated arrival time (ETA)

2. **Rating System**
   - Buyer ratings for riders
   - Rider ratings for buyers
   - Performance metrics

3. **Push Notifications**
   - New order available
   - Customer arrived notifications
   - Order completion confirmation

4. **Payment Integration**
   - Automatic payout system
   - Payment history
   - Tax documentation

5. **Analytics Dashboard**
   - Weekly/monthly earnings trends
   - Performance metrics
   - Delivery statistics

6. **Support System**
   - In-app chat with support
   - Issue reporting
   - Rating/feedback

---

## 📝 Notes for Developers

### Key Files to Know

| File | Purpose |
|------|---------|
| `lib/services/rider_auth_service.dart` | Authentication logic |
| `lib/services/rider_application_service.dart` | Role management |
| `lib/models/order.dart` | Order data model |
| `lib/screens/rider/rider_login_screen.dart` | Rider login UI |
| `lib/screens/rider/rider_dashboard_screen.dart` | Main dashboard |
| `lib/screens/rider/rider_available_orders_screen.dart` | Order listing |
| `lib/screens/rider/rider_delivery_detail_screen.dart` | Delivery tracking |
| `lib/screens/rider/rider_earnings_screen.dart` | Earnings view |

### Dependencies Required

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.0.0
  uuid: ^4.0.0
```

### Common Issues & Solutions

**Issue:** Rider can't login after registration
- **Solution:** Verify password is stored correctly in SharedPreferences

**Issue:** Orders not appearing
- **Solution:** Check order status is `toShip` and no rider is assigned

**Issue:** Earnings not updating
- **Solution:** Verify order status is set to `delivered` before earnings calculation

---

## 📞 Support

For issues or questions about the Rider Portal implementation, refer to:
1. The inline comments in each screen file
2. The RiderAuthService documentation
3. The Order model status definitions

---

**Last Updated:** April 27, 2024
**Version:** 1.0.0
