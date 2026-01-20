A blockchain-based solution for transparent metal smelting output verification using IoT sensors and smart contracts.

## ⚡ Problem Statement

Smelting companies can misreport their yields to avoid taxes and royalties, leading to revenue loss for governments and stakeholders.

## 🎯 Solution

Smart contracts connected to IoT weight sensors that automatically log refined metal output to the blockchain, ensuring transparency and accurate tax/royalty calculations.

## 🚀 Key Features

- 📊 **Real-time Output Logging**: IoT sensors automatically record smelting output
- 🔍 **Automated Verification**: Compare sensor data with reported figures
- 💰 **Tax & Royalty Calculation**: Automatic calculation based on actual output
- 🛡️ **Tamper-Proof Records**: Immutable blockchain storage
- ⚠️ **Discrepancy Detection**: Identifies reporting inconsistencies with penalties
- 📝 **Comprehensive Audit Trail**: Track all critical actions with timestamped logs for enhanced transparency and compliance
- ⏸️ **Emergency Pause Mechanism**: Admin-controlled contract pause functionality for emergency situations, ensuring operational safety and risk mitigation
- 👤 **Voluntary Deactivation**: Smelter owners can self-deactivate their facilities for better control

## 📋 Contract Functions

### Smelter Management
- `register-smelter` - Register a new smelting facility
- `deactivate-smelter` - Deactivate a smelter (admin only)
- `deactivate-own-smelter` - Allow smelter owners to deactivate their own facilities
- `get-smelter-summary` - View smelter statistics

### Sensor Management  
- `authorize-sensor` - Authorize IoT sensors for a smelter
- `deactivate-sensor` - Deactivate a sensor (admin only)

### Output Tracking
- `log-output` - Record output from IoT sensors
- `bulk-log-outputs` - Record multiple outputs in batch
- `submit-reported-output` - Submit manual output reports

### Verification & Tax
- `verify-output` - Compare actual vs reported output and calculate taxes
- `set-tax-rates` - Update global tax/royalty rates (admin only)
- `update-smelter-rates` - Set custom rates per smelter (admin only)
- `pay-taxes-and-royalties` - Direct payment of accumulated taxes and royalties

### Audit Trail
- `get-audit-entry` - Retrieve specific audit log entries
- `register-smelter-with-audit` - Register smelter with audit logging
- `log-output-with-audit` - Log output with audit trail
- `submit-reported-output-with-audit` - Submit reports with audit logging
- `verify-output-with-audit` - Verify output with audit trail
- `pay-taxes-and-royalties-with-audit` - Pay taxes with audit logging

### Emergency Controls
- `pause-contract` - Pause all contract operations (admin only)
- `unpause-contract` - Resume contract operations (admin only)
- `is-contract-paused` - Check current pause status

## 🛠️ Usage

### 1. Register Your Smelter
```clarity
(contract-call? .smelter-verification register-smelter 
  "Global Metals Inc" 
  "New York, USA" 
  "SM-2024-001")
```

### 2. Authorize IoT Sensors
```clarity
(contract-call? .smelter-verification authorize-sensor 
  "SENSOR-001" 
  u1 
  "weight-scale")
```

### 3. Log Output (Automated by IoT)
```clarity
(contract-call? .smelter-verification log-output 
  "SENSOR-001" 
  "gold" 
  u1500 
  u99 
  "BATCH-2024-001")
```

### 4. Submit Manual Reports
```clarity
(contract-call? .smelter-verification submit-reported-output 
  u1 
  u202401 
  "gold" 
  u1400 
  u98)
```

### 5. Verify and Calculate Taxes
```clarity
(contract-call? .smelter-verification verify-output u1 u202401)
```

## 📊 Data Structure

### Smelter Record
- Owner, name, location, license number
- Tax and royalty rates
- Total actual vs reported output
- Total taxes and royalties owed

### Output Logs
- Timestamp, metal type, weight, purity
- Sensor ID and batch tracking
- Verification status

### Verification Results
- Discrepancy calculations
- Tax and penalty amounts
- Verification status

### Audit Trail Records
- Action type, timestamp, and details
- Smelter-specific activity logs
- Immutable chronological history

## 🔒 Security Features

- ✅ Owner-only smelter operations
- ✅ Admin-controlled sensor authorization
- ✅ Input validation and error handling
- ✅ Authorized sensor checks
- ✅ Immutable audit trail
- ✅ Comprehensive action logging for all critical operations
- ✅ Emergency pause mechanism for operational safety

## 💡 Benefits

- 🎯 **Accurate Tax Collection**: Based on actual, not reported output
- 🔍 **Fraud Prevention**: Immutable sensor data prevents manipulation
- ⚡ **Real-time Monitoring**: Continuous output tracking
- 📈 **Data Analytics**: Historical production analysis
- 🏛️ **Regulatory Compliance**: Transparent reporting for authorities
- 🛑 **Emergency Response**: Quick contract suspension capability for critical situations
- 🎛️ **Owner Empowerment**: Direct control over facility status without admin dependency

## 🚀 Getting Started

1. Deploy the contract to Stacks blockchain
2. Register your smelting facility
3. Install and authorize IoT weight sensors
4. Connect sensors to blockchain via API
5. Monitor real-time output and tax calculations

## 🔧 Development

```bash
# Check contract syntax
clarinet check

# Run tests
npm install
npm test

# Deploy locally
clarinet integrate
```

## 📄 License

MIT License - Feel free to contribute and improve the platform!
