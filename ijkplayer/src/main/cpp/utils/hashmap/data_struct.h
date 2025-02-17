/*********************************************************************************************************
** 文   件   名: data_struct.h
**
** 创   建   人: 齐鲁桐
**
** 文件创建日期: 2019 年 2 月 21 日
**
** 描        述: 一些自定义数据结构的头文件.
*********************************************************************************************************/
#ifndef __DATA_STRUCT__H__
#define __DATA_STRUCT__H__

/*********************************************************************************************************
  需要引入的头文件
*********************************************************************************************************/
#include <stdio.h>  // 标准库
#include <stdlib.h> // 标准库
#include <string.h> // 标准库
/*********************************************************************************************************
  宏定义
*********************************************************************************************************/
#define NEW(type) (type *)malloc(sizeof(type)) // 分配内存
#define XFREE(x) \
    free(x);     \
    x = NULL;         // 释放内存，指针指向NULL
#define STRING char * // 字符串类型
/*********************************************************************************************************
  数据结构
*********************************************************************************************************/
enum _Boolean { True = 1,
    False            = 0 };
typedef enum _Boolean Bool; // 布尔类型

typedef struct list {
    STRING       value; // 值
    struct list *last;  // 上一节点
    struct list *next;  // 下一节点
} * List;               // 链表

typedef struct hashentry {
    void *            key;   // 键
    void *            value; // 值
    struct hashentry *next;  // 冲突链表
} * HashEntry;               // HashMap存储列表

typedef struct hashmap *HashMap; // 定义HashMap

// 函数指针
typedef int (*HashCode)(HashMap map, void *key);              // 指向哈希函数
typedef Bool (*HashEqual)(void *key1, void *key2);            // 指向判等函数
typedef void (*HashPut)(HashMap map, const void *key, const void *value); // 指向添加键值对的函数
typedef void *(*HashGet)(HashMap map, void *key);             // 指向获取键对应值的函数
typedef Bool (*HashRemove)(HashMap map, void *key);           // 指向删除键值对的函数
typedef void (*HashClear)(HashMap map);                       // 指向清空map的函数
typedef Bool (*HashExists)(HashMap map, void *key);           // 指向判断键值是否存在的函数

typedef struct hashmap {
    HashEntry  list;     // 存储列表
    int        listSize; // 存储空间大小
    int        size;     // 已使用大小（有多少个键值对）
    HashCode   hashCode; // 哈希函数
    HashEqual  equal;    // 判等函数
    HashPut    put;      // 添加键值对的函数
    HashGet    get;      // 获取键对应值的函数
    HashRemove remove;   // 删除键值对的函数
    HashClear  clear;    // 清空map的函数
    HashExists exists;   // 判断键值是否存在的函数
} * HashMap;             // 定义HashMap

typedef struct hashmapiterator {
    HashMap   hashMap;  // 要迭代的HashMap
    HashEntry entry;    // 迭代器当前指向
    int       hashCode; // 键值对的哈希值
    int       count;    // count
} * HashMapIterator;    // HashMap迭代器

/*********************************************************************************************************
  链表方法
*********************************************************************************************************/
List list_create();                      // 创建链表
List list_head(List list);               // 返回链表头部
List list_tail(List list);               // 返回链表尾部
List list_index(List list, int index);   // 使用索引查找链表
List list_append(List list, STRING str); // 链表增加项
List list_remove(List list, STRING str); // 链表删除项
List list_change(List list, STRING str); // 链表修改项
void list_delete(List list);             // 删除链表

/*********************************************************************************************************
  HashMap方法
*********************************************************************************************************/
HashMap hashmap_create(); // 创建HashMap

int default_HashCode(HashMap map, void *key); // 哈希函数

void hashmap_reset(HashMap hashMap, int listSize);     // 重置HashMap存储大小
void hashmap_delete(HashMap map);                      // 删除HashMap
void hashmap_put(HashMap map, void *key, void *value); // 添加键值对的函数
void hashmap_clear(HashMap map);                       // 清空map的函数

void *hashmap_get(HashMap map, void *key); // 获取键对应值函数

Bool hashmap_equal(void *key1, void *key2);     // 判等函数
Bool hashmap_exists(HashMap map, void *key);    // 判断键值是否存在的函数
Bool hashmap_remove(HashMap map, void *key);    // 删除键值对的函数
Bool hashmap_hasNext(HashMapIterator iterator); // 判断HashMap是否迭代完

HashMapIterator hashmap_iterator(HashMap map);          // 创建HashMap迭代器
HashMapIterator hashmap_next(HashMapIterator iterator); // 获取HashMap的下一项
STRING          string_copy(STRING str);

#endif
/*********************************************************************************************************
  END
*********************************************************************************************************/
