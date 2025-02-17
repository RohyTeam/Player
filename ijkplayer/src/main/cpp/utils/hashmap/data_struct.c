/*********************************************************************************************************
** 文   件   名: data_struct.c
**
** 创   建   人: 齐鲁桐
**
** 文件创建日期: 2018 年 2 月 22 日
**
** 描        述: 数据结构实现
*********************************************************************************************************/
/*********************************************************************************************************
  相关头文件
*********************************************************************************************************/
#include "data_struct.h"

/*********************************************************************************************************
  宏定义
*********************************************************************************************************/

/*********************************************************************************************************
  全局变量
*********************************************************************************************************/

/*********************************************************************************************************
** 函数名称: string_copy
** 功能描述: 字符串拷贝
** 输　入  :
** 输　出  :
** 全局变量:
** 调用模块:
*********************************************************************************************************/
STRING string_copy(STRING str)
{
    char *result = malloc(strlen(str) + 1); // +1是为了终止符
    strcpy(result, str);                    // 复制字符串

    return result;
}

/*********************************************************************************************************
** 函数名称: list_create
** 功能描述: 创建一个双向链表
** 输　入  : 字符串
** 输　出  : 链表
** 全局变量:
** 调用模块:
*********************************************************************************************************/
List list_create()
{
    List list = NEW(struct list); // 申请内存
    // 初始化赋值
    list->value = NULL;
    list->last  = NULL;
    list->next  = NULL;

    return list;
}
/*********************************************************************************************************
** 函数名称: list_head
** 功能描述: 移动到链表头节点
** 输　入  : 字符串
** 输　出  : 链表
** 全局变量:
** 调用模块:
*********************************************************************************************************/
List list_head(List list)
{
    List head = list;

    while (head->last != NULL) {
        head = head->last; // 移动到头节点
    }

    return head;
}
/*********************************************************************************************************
** 函数名称: list_create
** 功能描述: 移动到链表尾节点
** 输　入  : 字符串
** 输　出  : 链表
** 全局变量:
** 调用模块:
*********************************************************************************************************/
List list_tail(List list)
{
    List tail = list;

    while (tail->next != NULL) {
        tail = tail->next; // 移动到尾节点
    }

    return tail;
}
/*********************************************************************************************************
** 函数名称: list_index
** 功能描述:
** 输　入  :
** 输　出  :
** 全局变量:
** 调用模块:
*********************************************************************************************************/
List list_index(List list, int index)
{
    List node = list; // 头节点

    int i = 0;
    while (i < index && node != NULL) {
        node = node->next; // 指向下一个节点
        i++;               // 索引加一
    }
    if (node == NULL) { // 判断索引节点是否存在
        printf("Index Out Of Bounds\n");

        return NULL;
    }

    return node;
}
/*********************************************************************************************************
** 函数名称: list_append
** 功能描述: 为链表增加新项
** 输　入  : list 链表
**           str  字符串
** 输　出  : 新链表
** 全局变量:
** 调用模块:
*********************************************************************************************************/
List list_append(List list, STRING str)
{
    List head     = list;             // 头节点
    List node     = head;             // 当前节点
    List new_node = list_create(str); // 新节点，初始化value值

    while (node->next != NULL) {
        node = node->next; // 移动到最后一个节点
    }

    new_node->last = node;     // 新节点指向末尾节点
    node->next     = new_node; // 末尾节点指向新节点

    return head;
}
/*********************************************************************************************************
** 函数名称: list_remove
** 功能描述:
** 输　入  :
** 输　出  :
** 全局变量:
** 调用模块:
*********************************************************************************************************/
List list_remove(List list, STRING str)
{
    List head = list_head(list); // 头节点
    List node = head;            // 当前节点

    while (node != NULL) {
        if (strcmp(node->value, str) == 0) {       // 查询是否要删除当前节点
            if (node->last != NULL) {              // 若不是头节点
                if (node->next != NULL) {          // 若不是尾节点
                    node->next->last = node->last; // 下一节last点指向上一节点
                    node->last->next = node->next; // 上一节点next指向下一节点
                } else {
                    node->last->next = NULL; // 尾节点next指向NULL
                }
            } else {
                node->next->last = NULL;       // 头节点last指向NULL
                head             = node->next; // 头节点指向下一节点
            }
            free(node); // 删除当前节点
            break;
        }
        node = node->next;
    }
    if (node == NULL) {
        printf("node %s is not exist\n", str);
        return head;
    }

    return head;
}

/*********************************************************************************************************
** 函数名称: list_remove
** 功能描述:
** 输　入  :
** 输　出  :
** 全局变量:
** 调用模块:
*********************************************************************************************************/
void list_delete(List list)
{
    List head = list_head(list); // 移动到头节点
    List node = head;            // 当前节点

    while (head != NULL) {
        node = head;
        XFREE(head); // 删除当前节点
        head = node->next;
    }
}

/*********************************************************************************************************
** 函数名称: hashmap_delete_entry
** 功能描述: 删除节点，释放内存
** 输　入  :
** 输　出  :
** 全局变量:
** 调用模块:
*********************************************************************************************************/
void hashmap_delete_entry(HashEntry entry)
{
    XFREE(entry->key);
    XFREE(entry->value);
    XFREE(entry);

    return;
}

/*********************************************************************************************************
** 函数名称: hashmap_create
** 功能描述: 创建HashMap
** 输　入  :
** 输　出  : 一个HashMap
** 全局变量:
** 调用模块:
*********************************************************************************************************/
HashMap hashmap_create()
{
    HashMap hashMap = NEW(struct hashmap); // 申请内存

    hashMap->size     = 0;                // 当前占用为0
    hashMap->listSize = 8;                // 默认存储大小为8
    hashMap->hashCode = default_HashCode; // 设置哈希函数
    hashMap->equal    = hashmap_equal;    // 设置判等函数
    hashMap->put      = hashmap_put;      // 设置添加键值对函数
    hashMap->get      = hashmap_get;      // 设置获取键对应值函数
    hashMap->remove   = hashmap_remove;   // 设置删除键值对函数
    hashMap->clear    = hashmap_clear;    // 设置清空map函数
    hashMap->exists   = hashmap_exists;   // 设置判断键值是否存在函数

    hashMap->list = (HashEntry)malloc(hashMap->listSize * sizeof(struct hashentry)); // 初始化存储申请8个内存空间

    // 初始化所有属性为NULL
    int i = 0;
    for (i = 0; i < hashMap->listSize; ++i) {
        hashMap->list[i].key   = NULL;
        hashMap->list[i].value = NULL;
        hashMap->list[i].next  = NULL;
    } // 初始化结束

    return hashMap;
}

/*********************************************************************************************************
** 函数名称: hashmap_iterator
** 功能描述: 生成HashMap的迭代器
** 输　入  : hashMap: HashMap
**
**
** 输　出  : HashMap的迭代器
** 全局变量:
** 调用模块:
*********************************************************************************************************/

HashMapIterator hashmap_iterator(HashMap hashMap)
{
    HashMapIterator iterator = NEW(struct hashmapiterator); // 申请内存

    iterator->hashMap  = hashMap; // 指向要迭代的HashMap
    iterator->entry    = NULL;    // 当前指向的键值对
    iterator->count    = 0;       // 已迭代次数
    iterator->hashCode = -1;      // 对应哈希码

    return iterator;
}
/*********************************************************************************************************
** 函数名称: hashmap_hasNext
** 功能描述: 判断HashMap是否迭代完
** 输　入  : hashMap: HashMap
**
**
** 输　出  : 若迭代次数小于HashMap元素个数，返回True，否则返回False
** 全局变量:
** 调用模块:
*********************************************************************************************************/
Bool hashmap_hasNext(HashMapIterator iterator)
{
    return iterator->count < iterator->hashMap->size ? True : False; // 判断当前迭代次数
}
/*********************************************************************************************************
** 函数名称: hashmap_next
** 功能描述: 获取HashMap的下一项，保存在迭代器的entry属性里
** 输　入  : hashMap: HashMap
**
**
** 输　出  : 返回带有迭代器
** 全局变量:
** 调用模块:
*********************************************************************************************************/
HashMapIterator hashmap_next(HashMapIterator iterator)
{
    if (hashmap_hasNext(iterator)) {                                    // 判断是否迭代完
        if (iterator->entry != NULL && iterator->entry->next != NULL) { // 判断是否是冲突链表
            iterator->count++;                                          // 迭代次数加一
            iterator->entry = iterator->entry->next;                    // 指向当前节点的下一个节点
            return iterator;
        }
        while (++iterator->hashCode < iterator->hashMap->listSize) { // 迭代列表
            HashEntry entry = &iterator->hashMap->list[iterator->hashCode];
            // 获取对应节点
            if (entry->key != NULL) {    // 若不为空，则跳出
                iterator->count++;       // 迭代次数加一
                iterator->entry = entry; // 指向该节点
                break;
            }
        }
    }

    return iterator;
}

/*********************************************************************************************************
** 函数名称: hashmap_reset
** 功能描述: 重新设置HashMap的内存大小，不够时扩容，过大时缩小
** 输　入  : hashMap: HashMap
**           key:     键
**
**
** 输　出  : 整数型哈希码
** 全局变量:
** 调用模块:
*********************************************************************************************************/

void hashmap_reset(HashMap hashMap, int listSize)
{
    if (listSize < 8) {
        return; // 必须大于等于8个空间
    }

    HashEntry tmpList = (HashEntry)malloc(hashMap->size * sizeof(struct hashentry));
    // 创建临时存储空间
    HashMapIterator iterator = hashmap_iterator(hashMap); // 创建迭代器

    int length = hashMap->size; // 保存元素个数

    // 将数据存入临时列表
    int i = 0;
    for (i = 0; hashmap_hasNext(iterator); i++) {
        iterator         = hashmap_next(iterator);
        tmpList[i].key   = iterator->entry->key;
        tmpList[i].value = iterator->entry->value;
        tmpList[i].next  = NULL;
    }

    XFREE(iterator); // 释放内存

    // 清理HashMap中的冲突链表
    hashMap->size = 0;

    for (i = 0; i < hashMap->listSize; i++) {  // 遍历HashMap的存储列表
        HashEntry current = &hashMap->list[i]; // 获取节点

        current->key   = NULL;
        current->value = NULL;

        if (current->next != NULL) {                  // 处理冲突链表
            while (current->next != NULL) {           // 遍历存储列表
                HashEntry temp = current->next->next; // 临时节点指向下下个节点
                free(current->next);                  // 释放下个节点
                current->next = temp;                 // 下一节点指向临时节点
            }
        }
    } // 清理结束

    hashMap->listSize = listSize; // 重置内存大小
    HashEntry relist  = (HashEntry)realloc(hashMap->list, hashMap->listSize * sizeof(struct hashentry));
    if (relist != NULL) {
        hashMap->list = relist; // 指向新内存
        relist        = NULL;
    } // 重置内存大小结束

    // 初始化数据
    for (i = 0; i < hashMap->listSize; i++) {
        hashMap->list[i].key   = NULL;
        hashMap->list[i].value = NULL;
        hashMap->list[i].next  = NULL;
    }

    for (i = 0; i < length; i++) {
        hashMap->put(hashMap, tmpList[i].key, tmpList[i].value); // 将所有键值对重新写入内存
        XFREE(tmpList[i].key);                                   // 释放内存
        XFREE(tmpList[i].value);
    }
    XFREE(tmpList); // 释放内存
}

/*********************************************************************************************************
** 函数名称: default_HashCode
** 功能描述: 生成哈希码
** 输　入  : hashMap: HashMap
**           key:     键
**
**
** 输　出  : 整数型哈希码
** 全局变量:
** 调用模块:
*********************************************************************************************************/
int default_HashCode(HashMap hashMap, void *key)
{
    char *       str  = (STRING)key; // 转换为字符串
    unsigned int seed = 131;         // 31 131 1313 13131 131313 etc..
    unsigned int hash = 0;

    while (*str) {
        hash = hash * seed + (*str++);
    }

    return (hash & 0x7FFFFFFF) % hashMap->listSize;
}
/*********************************************************************************************************
** 函数名称: hashmap_equal
** 功能描述: 判断输入的字符串是否相等
** 输　入  : key1:
**           key2:
**
** 输　出  : 布尔值
** 全局变量:
** 调用模块:
*********************************************************************************************************/
Bool hashmap_equal(void *key1, void *key2)
{
    return strcmp((STRING)key1, (STRING)key2) ? False : True;
}
/*********************************************************************************************************
** 函数名称: hashmap_put
** 功能描述: 将键值对存到HashMap中
** 输　入  : hashMap:
**           key:
**           value:
**
** 输　出  : 布尔值
** 全局变量:
** 调用模块:
*********************************************************************************************************/
void hashmap_put(HashMap hashMap, void *key1, void *value1)
{
    if(!key1 || !value1){
        return;
    }
    STRING key   = string_copy(key1);   // 拷贝字符串
    STRING value = string_copy(value1); // 记得销毁

    if (hashMap->size >= hashMap->listSize) {

        // 内存扩充至原来的两倍
        // *注: 扩充时考虑的是当前存储元素数量与存储空间的大小关系，而不是存储空间是否已经存满，
        // 例如: 存储空间为10，存入了10个键值对，但是全部冲突了，所以存储空间空着9个，其余的全部挂在一个上面，
        // 这样检索的时候和遍历查询没有什么区别了，可以简单这样理解，当我存入第11个键值对的时候一定会发生冲突，
        // 这是由哈希函数本身的特性(取模)决定的，冲突就会导致检索变慢，所以这时候扩充存储空间，对原有键值对进行
        // 再次散列，会把冲突的数据再次分散开，加快索引定位速度。
        hashmap_reset(hashMap, hashMap->listSize * 2); // 重置内存
    }

    int index = hashMap->hashCode(hashMap, key); // 计算哈希码

    if (hashMap->list[index].key == NULL) { // 对应地址为空直接存储
        hashMap->list[index].key   = key;   // 保存key
        hashMap->list[index].value = value; // 保存value
        hashMap->size++;                    // 键值对数量加一

        return;
    } else {
        HashEntry current = &hashMap->list[index];

        while (current != NULL) {
            if (hashMap->equal(key, current->key)) {
                hashMap->list[index].value = value; // 对于键值已经存在的直接覆盖
                return;
            }
            current = current->next;
        };

        HashEntry entry = NEW(struct hashentry); // 对于键值不存在的创建新节点

        entry->key   = key;   // 保存key
        entry->value = value; // 保存value

        entry->next               = hashMap->list[index].next; // 将新节点插入第一个节点之后
        hashMap->list[index].next = entry;

        hashMap->size++; // 键值对计数加一
    }
}

/*********************************************************************************************************
** 函数名称: hashmap_get
** 功能描述:
** 输　入  : hashMap
**           key 字符串
**
**
** 输　出  : key所对应的value
** 全局变量:
** 调用模块:
*********************************************************************************************************/
void *hashmap_get(HashMap hashMap, void *key)
{
    int index = hashMap->hashCode(hashMap, key); // 获取哈希码

    HashEntry entry = &hashMap->list[index]; // 使用索引

    if (entry->key == NULL) {
        printf("This key %s does not exist.\n", (STRING)key);
        return NULL;
    }

    while (entry != NULL && entry->key != NULL && !hashMap->equal(entry->key, key)) {
        // 判断key值是否相等
        entry = entry->next;
    }

    return entry->value; // 返回value
}
/*********************************************************************************************************
** 函数名称: hashmap_exists
** 功能描述: 判断输入的字符串是否相等
** 输　入  : key1:
**           key2:
**
** 输　出  : 布尔值
** 全局变量:
** 调用模块:
*********************************************************************************************************/
Bool hashmap_exists(HashMap map, void *key)
{
    int index = map->hashCode(map, key); // 获取哈希码

    HashEntry entry = &map->list[index];

    while (entry != NULL && entry->key != NULL) {
        // 判断key值是否相等
        if (map->equal(entry->key, key)) {
            return True;
        }
        entry = entry->next;
    }

    return False;
}
/*********************************************************************************************************
** 函数名称: hashmap_remove
** 功能描述: 判断输入的字符串是否相等
** 输　入  : key1:
**           key2:
**
** 输　出  : 布尔值
** 全局变量:
** 调用模块:
*********************************************************************************************************/
Bool hashmap_remove(HashMap hashMap, void *key)
{
    int index = hashMap->hashCode(hashMap, key); // 获取哈希码

    HashEntry entry = &hashMap->list[index]; // 移动到要删除的节点

    if (entry->key == NULL) {
        return False; // 若不存在key，返回False
    }

    Bool result = False;

    if (hashMap->equal(entry->key, key)) { // 若头节点key相等
        if (entry->next != NULL) {         // 若存在冲突链表，将当前节点
            HashEntry temp = entry->next;  // 更新为冲突链表中下一个节点

            XFREE(entry->key);          // 清理key
            XFREE(entry->value);        // 清理value
            entry->key   = temp->key;   // 更新key
            entry->value = temp->value; // 更新value
            entry->next  = temp->next;  // 此时有两个一样的头节点

            XFREE(temp); // 删除一个头节点
        } else {
            XFREE(entry->key); // 若不存在冲突链表，清理
            XFREE(entry->value);
        }
        hashMap->size--; // 元素计数减一
        result = True;
    } else { // 若头节点key不相等
        HashEntry p = entry;

        entry = entry->next;
        while (entry != NULL) { // 遍历冲突链表
            if (hashMap->equal(entry->key, key)) {

                p->next = entry->next;       // last节点指向next节点
                hashmap_delete_entry(entry); // 删除该节点

                hashMap->size--; // 元素计数减一
                result = True;

                break;
            }
            p     = entry;
            entry = entry->next;
        };
    }

    // 如果空间占用不足一半，则释放多余内存
    if (hashMap->size < hashMap->listSize / 2) {
        hashmap_reset(hashMap, hashMap->listSize / 2);
    }

    return result;
}
/*********************************************************************************************************
** 函数名称: hashmap_clear
** 功能描述: 清空HashMap，执行完后HashMap变为刚创建时的形态
** 输　入  : hashMap:
**
** 输　出  : 布尔值
** 全局变量:
** 调用模块:
*********************************************************************************************************/
void hashmap_clear(HashMap hashMap)
{
    // 遍历存储列表
    int i = 0;
    for (i = 0; i < hashMap->listSize; i++) {
        HashEntry entry = hashMap->list[i].next;
        while (entry != NULL) {           // 遍历冲突链表
            HashEntry next = entry->next; // 指向下一个节点
            hashmap_delete_entry(entry);  // 删除当前节点
            entry = next;                 // 更新为下一个节点
        }
        hashMap->list[i].next = NULL;
    }

    for (i = 0; i < hashMap->listSize; ++i) {
        XFREE(hashMap->list[i].key);
        XFREE(hashMap->list[i].value);
    }

    free(hashMap->list); // 释放存储空间

    hashMap->size     = 0; // 当前占用为0
    hashMap->listSize = 8; // 默认存储大小为8

    // 初始化存储申请8个内存空间
    hashMap->list = (HashEntry)malloc(hashMap->listSize * sizeof(struct hashentry));

    // 初始化所有属性为NULL
    for (i = 0; i < hashMap->listSize; ++i) {
        hashMap->list[i].key   = NULL;
        hashMap->list[i].value = NULL;
        hashMap->list[i].next  = NULL;
    }
}

/*********************************************************************************************************
** 函数名称: hashmap_delete
** 功能描述: 判断输入的字符串是否相等
** 输　入  : key1:
**           key2:
**
** 输　出  : 布尔值
** 全局变量:
** 调用模块:
*********************************************************************************************************/
void hashmap_delete(HashMap hashMap)
{
    hashmap_clear(hashMap); // 清空HashMap

    XFREE(hashMap->list); // 清理存储列表
    XFREE(hashMap);       // 清理结构体
}
/*********************************************************************************************************
  END
*********************************************************************************************************/
