#!/bin/bash
set -u

# 実行場所のディレクトリを取得
THIS_DIR=$(cd $(dirname $0); pwd)

cd $THIS_DIR
git submodule init
git submodule update

echo "start setup..."
for f in .??*; do
    [ "$f" = ".git" ] && continue
    [ "$f" = ".DS_Store" ] && continue
    
    # 既存のファイルがある場合はバックアップや確認が必要かもしれませんが
    # 記事の通り ln -snfv で上書き(シンボリックリンク張り替え)を行います
    ln -snfv "$THIS_DIR/$f" ~/
done

cat << END
**************************************************
DOTFILES SETUP FINISHED! bye.
**************************************************
END
