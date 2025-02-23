export interface CategoryItem {

  type: string
  uri: string

}

export interface CategoryVideo {

  hash: string

}

export interface CategoryFolder {

  name: string
  items: CategoryItem[]

}

export interface CategoryScan {

}