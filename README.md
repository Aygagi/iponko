# IponKo 🐷
### Student Savings App — Philippines
**Flutter Frontend + REST API Backend**
> "Mag-ipon tayo!" — A habit-building savings app for Filipino students and their parents.

---

## 👥 Team

| Role | Name | Branch |
|---|---|---|
| Frontend (Flutter) | Joshua | `frontend` |
| Backend (API) | Jhed | `backend` |

---

## 📌 Project Status

| Layer | Status |
|---|---|
| Flutter project scaffold | ✅ Done |
| Data models (User, Goal, Deposit, Badge) | ✅ Done |
| Student Dashboard | ✅ Done |
| Add Deposit screen | ✅ Done |
| Offline storage (Hive) | ✅ Done |
| Repository interface (API-ready) | ✅ Done |
| Backend API | 🔄 In progress (Jhed) |
| Create Goal screen | 🔄 In progress (Joshua) |
| Auth / Sign Up / PIN | 🔄 In progress (Joshua) |

---

## 🔧 For Jhed — Backend Developer

Hey Jhed! Everything on the frontend is designed so your backend plugs in cleanly with **zero UI changes**. Here's exactly what you need to know.

---

### 📁 The One File You Need to Match

**`iponko/lib/repositories/ipon_repository.dart`**

This is the abstract interface the frontend uses. Your backend API needs to fulfill every method in this file. The frontend never calls your API directly — it goes through this interface.

When your API is ready, we just create `api_repository.dart` implementing this interface, and swap one line in `app_providers.dart`. That's it.

---

### 📦 Agreed JSON Contract

These are the exact model shapes the frontend expects. Your API responses **must match these field names and types**.

#### User
```json
{
  "id": "string (UUID)",
  "name": "string",
  "email": "string",
  "role": "student | parent",
  "school": "string | null",
  "gradeLevel": "int | null",
  "linkedChildId": "string | null",
  "linkedParentId": "string | null",
  "createdAt": "ISO 8601 datetime string"
}
```

#### Goal
```json
{
  "id": "string (UUID)",
  "userId": "string",
  "name": "string",
  "targetAmount": "double",
  "currentAmount": "double",
  "targetDate": "ISO 8601 datetime string",
  "createdAt": "ISO 8601 datetime string",
  "status": "active | completed | archived",
  "emoji": "string | null"
}
```

#### Deposit
```json
{
  "id": "string (UUID)",
  "userId": "string",
  "goalId": "string | null",
  "amount": "double",
  "source": "allowance | baon | gift | other",
  "date": "ISO 8601 datetime string",
  "note": "string | null",
  "isApprovedByParent": "boolean",
  "createdAt": "ISO 8601 datetime string"
}
```

---

### 🌐 Expected API Endpoints

These are the endpoints the frontend will call. Build these in order of priority.

#### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login, returns token |
| GET | `/api/auth/me` | Get current user from token |

#### Goals
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/goals?userId=` | Get all goals for a user |
| POST | `/api/goals` | Create a new goal |
| PUT | `/api/goals/:id` | Update a goal |
| DELETE | `/api/goals/:id` | Delete a goal |

#### Deposits
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/deposits?userId=` | Get all deposits for a user |
| POST | `/api/deposits` | Log a new deposit |
| DELETE | `/api/deposits/:id` | Delete a deposit |
| PATCH | `/api/deposits/:id/approve` | Parent approves a deposit |

#### Users
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/users/:id` | Get user by ID |
| PUT | `/api/users/:id` | Update user profile |
| POST | `/api/users/link` | Link parent to child via code |

---

### 🔐 Auth

Use **JWT Bearer tokens**. After login, the frontend will store the token and send it as:
```
Authorization: Bearer <token>
```

---

### 🔁 How the Swap Works

Once your API is ready, Joshua only needs to:

1. Create `iponko/lib/repositories/api_repository.dart` implementing `IponRepository`
2. Change **one line** in `iponko/lib/providers/app_providers.dart`:

```dart
// BEFORE (offline Hive):
return HiveRepository();

// AFTER (your API):
return ApiRepository(baseUrl: 'http://your-server-address/api');
```

Zero UI changes needed. The app just works online.

---

### 🚀 Getting Started (Jhed's Setup)

```bash
# Clone the repo
git clone https://github.com/Aygagi/iponko.git
cd iponko

# Create your backend branch
git checkout -b backend
git push -u origin backend

# Work in the backend/ folder
mkdir backend
cd backend
# Start your Spring Boot / Node.js project here
```

Keep all your backend code inside a `/backend` folder at the root of the repo so it stays separate from the Flutter code in `/iponko`.

---

### 📂 Repo Structure

```
iponko/                        ← Flutter frontend (Joshua)
  lib/
    models/                    ← JSON contracts live here
    repositories/
      ipon_repository.dart     ← Interface your API must match
      hive_repository.dart     ← Current offline implementation
    providers/
      app_providers.dart       ← Swap HiveRepository → ApiRepository here
backend/                       ← Your Spring Boot project (Jhed)
README.md
```

---

### ⚠️ Important Notes for Backend

- All amounts are in **Philippine Peso (PHP)** — store as `DECIMAL(10,2)` in your database
- `currentAmount` on goals is **computed from deposits** — either compute server-side or let the frontend compute it (we currently compute locally)
- `isSynced` field on models is **frontend-only** — you don't need to store it, it just tracks whether local data has been pushed to the API yet
- Dates are always **ISO 8601 format**: `2025-04-30T14:30:00.000Z`
- UUIDs are generated on the frontend — your backend should **accept client-generated IDs** or return new ones and let the frontend update

---

*IponKo — Integ 2 Final Project • BSIT AI & Robotics*
