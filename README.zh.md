[English](README.md) | 简体中文

# LRU

一个 LRU 缓存 Dart 实现。

## 特性

- 固定大小的 LRU 缓存
- 基于权重的容量管理
- 可配置的条目过期时间
- 缓存操作事件通知

## 快速开始

```dart
// 创建简单缓存
final cache = LruCache<String, int>(5);

// 基本操作
cache.put('key', 100);
final value = cache.fetch('key');  // 返回 100
cache.remove('key');               // 移除条目

// 检查存在性
if (cache.containsKey('key')) {
  // 键存在
}

// 获取所有条目
final values = cache.values();
final keys = cache.keys();
```

## 高级用法

### 自动值计算

```dart
// 不存在时计算值
final value = cache.getOrAdd('key', () {
  return computeExpensiveValue();
});

// 异步计算
final value = await cache.getOrAddAsync('key', () async {
  return await fetchValueFromNetwork();
});
```

### 基于权重的驱逐

```dart
final options = LruOptions(
  maxWeight: 1000,
  defaultEntryOptions: EntryOptions(weight: 1)
);

final cache = LruCache<String, int>(50, options: options);

// 添加重量不同的项目
cache.putWithOptions('large', 100, EntryOptions(weight: 10));
cache.putWithOptions('small', 200, EntryOptions(weight: 1));
```

### 条目过期

```dart
// 全局过期设置
final cache = LruCache<String, int>(100, 
  options: LruOptions(
    defaultEntryOptions: EntryOptions(maxAge: 5000) // 5秒
  )
);

// 单个条目过期设置
cache.putWithOptions('temp', 100, 
  EntryOptions(maxAge: 1000) // 1秒
);
```

### 事件处理

```dart
final cache = LruCache<String, int>(100,
  options: LruOptions(
    onEvent: (event) {
      switch (event.type) {
        case CacheEventType.add:
          print('添加: ${event.key} = ${event.value}');
          break;
        case CacheEventType.expired:
          print('过期: ${event.key}');
          break;
      }
    }
  )
);
```

### 自定义使用跟踪

```dart
final options = LruOptions(
  usage: LruUsageOptions(
    fetchAddsUsage: true,    // 访问更新位置
    putAddsUsage: false,     // 添加不更新位置
    updateAddsUsage: true    // 更新时更新位置
  )
);

final cache = LruCache<String, int>(100, options: options);
```

## 性能建议

- 根据内存限制选择适当的容量
- 配置权重以更好地管理内存
- 对于写入密集型场景，考虑禁用使用跟踪
- 尽可能使用批量操作
- 监控缓存统计以获得最佳性能


## 许可证
```
MIT License lollipopkit
```
