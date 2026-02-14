# Dashboard Debugging Insight

**Date**: 2026-02-14
**Status**: Done

## Issue Summary

The MEPPI dashboard pages were not functioning properly:
- Promotions page crashed with NoMethodError
- Regional Prices page returned 500 error
- Competition page showed 0 channels for most phones
- Channel Strategy page showed "No prices found" message
- Country filter was not working correctly

## Initial Hypothesis

1. Database connection issues
2. Service layer bugs
3. View template errors

## Root Cause

1. **Data Linkage Issue**: Countries and Channels tables were empty (0 records) but MeppiTrade records (2288) referenced them via foreign keys
2. **Service Model Mismatch**: Services used `Price` model but data was in `MeppiTrade` model
3. **Error Handling Gap**: Controllers caught exceptions but didn't provide safe default values, causing views to crash on nil data access
4. **Pagination Incompatibility**: Used Kaminari-style `.page().per()` but project uses Pagy gem
5. **Country Filter Empty String Bug**: `if country_id` treated empty strings as truthy (should use `.present?`)

## Debugging Process

1. Analyzed debug screenshots from `/mnt/c/Users/thean/Downloads/debug`
2. Checked database state: 18 phones, 2288 trades, 0 channels, 0 countries
3. Discovered foreign key mismatch - trades referenced non-existent channels/countries
4. Created SQLite import script to migrate countries and channels data
5. Fixed service classes to use MeppiTrade instead of Price
6. Added error handling with safe defaults in controllers
7. Replaced Kaminari pagination with simple `.limit()` calls
8. Fixed empty string handling in country filters using `.present?`

## Solution

### 1. Data Import (scripts/import_data.rb)
```ruby
# Import countries from SQLite to PostgreSQL
sqlite_db.execute('SELECT id, code, name, currency, exchange_source, priority, active FROM countries').each do |row|
  Country.find_or_initialize_by(id: id).tap do |c|
    c.code = code
    c.name = name
    c.currency = currency
    c.exchange_source = exchange_source
    c.priority = priority
    c.active = active == 1
  end.save!
end
```

### 2. Controller Error Handling
```ruby
def promotions
  @promotions_data = PromotionService.active_promotions(country_id: country_id)
rescue StandardError => e
  handle_error(e, 'Promotions tracking')
  @promotions_data = default_promotions_data  # Safe defaults
end

def default_promotions_data
  { active_promotions: [], discount_ranking: [], total_count: 0, avg_discount: 0.0 }
end
```

### 3. Service Updates
- **CompetitionService**: Use `MeppiTrade` instead of `Price` model
- **ChannelStrategyService**: Fixed `if country_id` → `if country_id.present?`
- **PromotionService**: Handle nil data gracefully
- Replace `.page().per()` with `.limit()`

### 4. Country Filter Fix
```ruby
# Before (buggy - empty string is truthy in Ruby)
if country_id
  query = query.where(meppi_trades: { country_id: country_id })
end

# After (correct)
if country_id.present?
  query = query.where(meppi_trades: { country_id: country_id })
end
```

## Verification Results

### Competition Page - UAE Filter
- **Market Share**: Samsung 64.3%, Apple 35.7% (was 50/50 global)
- **S25 Ultra**: $4,020.51 avg (was $18,555 global)
- **Price Points**: 68 for S25 Ultra (UAE only)
- **Competitor Counts**: 8-13 per model (realistic)

### Channel Strategy Page - UAE Filter
- **Samsung Galaxy S25 Ultra in UAE**:
  - Price Range: $218 (Samsung Official) to $5,399 (mygsm.me)
  - Average: $4,020.51
  - Channels: Samsung UAE, du, Noon, Ecity, Etisalat, Amazon.ae, Sharaf DG, mygsm.me
  - Recommendations working: Best Value, Great Deal, Good Price, Fair Price, Overpriced

## Outstanding Issues

### Storage/Memory Info Not Available
- **Issue**: Model names don't include storage variants (128GB, 256GB, etc.)
- **Impact**: Prices for same model vary significantly ($218 to $5,399 for S25 Ultra)
- **Root Cause**: Phone table's `storage` and `ram` columns are empty
- **Recommendation**: Future data collection should include storage variant in title or separate field

## Key Insights

1. **Foreign Key Integrity**: Always ensure referenced records exist before creating dependent records
2. **Safe Defaults**: Controllers must provide safe default values when services fail
3. **Model Consistency**: Services should use the same model as the actual data source
4. **Pagination Gems**: Check which pagination gem is installed before using pagination methods
5. **Empty String Truthiness**: Ruby treats `''` as truthy - always use `.present?` for params

## Prevention

1. Add database constraints to prevent orphaned foreign keys
2. Add integration tests that verify data linkage
3. Add controller tests that verify error handling
4. Document which model each service should use
5. Use `.present?` instead of truthiness checks for all params

## Files Changed

- `app/controllers/dashboard_controller.rb` - Added safe defaults
- `app/controllers/competition_controller.rb` - Removed redirect on error
- `app/services/competition_service.rb` - Use MeppiTrade model, fix `.present?`
- `app/services/channel_strategy_service.rb` - Fix `.present?` for country_id
- `app/services/promotion_service.rb` - Handle errors gracefully
- `spec/controllers/competition_controller_spec.rb` - Updated tests
- `scripts/import_data.rb` - Data import script

## Commit

```
027ffef fix: dashboard pages and data linkage issues
```
