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

locals {
  initial_songs_data = {
    "song_000001" : {
      songName : "Test Song1",
      "artistId" : "artist_000001",
      "audioS3Key" : "tracks/system/test2.mp3",
      "durationSeconds" : "180"
    },
    "song_000002" : {
      songName : "Test Song2",
      "artistId" : "artist_000001",
      "audioS3Key" : "tracks/system/test2.mp3",
      "durationSeconds" : "120"
    }
  }
}

# テーブルアイテムの初期データ
resource "aws_dynamodb_table_item" "initial_songs_data" {
  for_each = local.initial_songs_data

  table_name = aws_dynamodb_table.music_tracks.name
  hash_key   = aws_dynamodb_table.music_tracks.hash_key

  item = <<-ITEM
  {
    "songId": {"S": "${each.key}"},
    "songName": {"S": "${each.value.songName}"},
    "artistId": {"S": "${each.value.artistId}"},
    "audioS3Key": {"S": "${each.value.audioS3Key}"},
    "durationSeconds": {"N": "${each.value.durationSeconds}"}
  }
  ITEM
}
