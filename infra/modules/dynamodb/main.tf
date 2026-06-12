resource "aws_dynamodb_table" "music_tracks" {
  name = "music_tracks"

  billing_mode   = "PROVISIONED"
  write_capacity = 1
  read_capacity  = 1

  # パーテーションキー
  hash_key = "songId"

  # 本番ではtrue
  deletion_protection_enabled = false

  # 属性
  attribute {
    name = "songId" # ローワーキャメルケース
    type = "S"      #　String型の[S]
  }

  # AWS側のオートスケーリングが数値を変更しても、Terraformはそれを「変更」とみなさない設定
  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity,
    ]
  }

  tags = {
    "created_by" = var.owner
  }
}

# テーブルアイテムの初期データ
resource "aws_dynamodb_table_item" "initial_songs_data" {
  for_each = { for item in jsondecode(file("${path.module}/music_items.json")) : item.songId.S => item }

  table_name = aws_dynamodb_table.music_tracks.name
  hash_key   = aws_dynamodb_table.music_tracks.hash_key

  item = jsonencode(each.value)

  lifecycle {
    ignore_changes = [item]
  }
}
