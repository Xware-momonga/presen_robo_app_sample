# -*- coding: utf-8 -*-

import json
import uuid
import sqlite3
import os
import zipfile
import shutil
from itertools import groupby
from operator import itemgetter

from bottle import run
from bottle import route
from bottle import template
from bottle import request
from bottle import static_file
from bottle import install
from bottle import abort
from bottle import HTTPResponse

from bottle_sqlite import SQLitePlugin


IMAGE_EXT = ['.png', '.jpg', '.jpeg']
UPLOAD_DIR = './presen_images'
STATIC_DIR = './static'


@route('/', method='GET')
def show_list(db):
    '''プレゼン一覧画面を表示'''

    # すべてのプレゼン情報を取得
    rows = db.execute('SELECT * FROM presen ORDER BY createdtimestamp').fetchall()
    presen_list = []
    for row in rows:
        presenid, title, created_timestamp = row
        presen_list.append({'id': presenid, 'title': title})

    return template('index.html', presen_list=presen_list)


@route('/addpresen', method='GET')
def show_add_presen_form():
    '''プレゼン登録画面を表示'''

    return template('add_presen.html')


@route('/registerpresen', method='POST')
def register_presen(db):
    '''プレゼン登録処理'''

    title = request.forms.title
    presenid = str(uuid.uuid4())

    if title:
        db.execute('INSERT INTO presen(id, title) VALUES (?, ?)', (presenid, title))

    # プレゼン一覧画面へ遷移する
    return show_list(db)


@route('/editpresen', method='GET')
def show_detail(db):
    '''プレゼン編集画面を表示'''

    presenid = request.query.presenid

    # presenid に紐づく ページ情報を取得
    rows = db.execute('SELECT * FROM page WHERE presenid = ?', (presenid,)).fetchall()
    page_list = []
    for row in rows:
        pageid, saytext, pageno, filename, presenid = row
        page_list.append({
            'id': pageid,
            'saytext': saytext,
            'pageno': pageno,
            'filename': filename,
            'presenid': presenid
        })

    return template('edit_presen.html', presenid=presenid, page_list=page_list)


@route('/updatepresen', method='POST')
def update_presen(db):
    '''プレゼン編集処理'''

    saytexts = request.forms.getall('saytext')
    presenid = request.forms.get('presenid')
    save_path = os.path.join(UPLOAD_DIR, '{presenid}').format(presenid=presenid)

    pages = []

    # 送信されたページ情報を登録・更新
    for pageno, saytext in enumerate(saytexts):

        pageid = request.forms.get('row_{number}'.format(number=str(pageno)))
        if not pageid:
            pageid = str(uuid.uuid4())

        image_file = None
        uploadfile = request.files.get('uploadfile_{number}'.format(number=str(pageno)))

        if uploadfile:

            name, ext = os.path.splitext(uploadfile.raw_filename)

            # 指定した拡張子以外のファイルがアップロードされた場合
            if ext.lower() not in IMAGE_EXT:
                return abort(code=500, text='The file extension is not allowed.')

            if not os.path.isdir(save_path):
                os.mkdir(save_path)

            image_file = pageid + ext.lower()
            save_file_path = '{path}/{file}'.format(path=save_path, file=image_file)
            uploadfile.save(save_file_path, overwrite=True)

        # 新規アップロードファイルが無い場合
        else:
            # 既存ページ情報を取得する
            row = db.execute('SELECT filename FROM page WHERE id = ?', (pageid,)).fetchone()
            if row is not None:
                image_file = row[0]

        if image_file:
            page = (
                pageid,
                saytext,
                pageno,
                image_file,
                presenid
            )

            pages.append(page)

    # ページ情報を DB に保存
    if len(pages) > 0:
        db.executemany('INSERT OR REPLACE INTO page(id, saytext, pageno, filename, presenid) VALUES (?, ?, ?, ?, ?)', pages)

    # プレゼン一覧画面へ遷移する
    return show_list(db)


@route('/deletepresen', method='POST')
def delete_presen(db):
    '''プレゼン削除処理'''

    presenid = request.forms.get('presenid')

    # 指定された presenid に紐づくプレゼン情報を削除
    db.execute('DELETE FROM presen WHERE id = ?', (presenid,))

    # 指定された presenid に紐づくページ情報を削除
    dir_path = os.path.join(UPLOAD_DIR, '{presenid}').format(presenid=presenid)
    if os.path.isdir(dir_path):
        db.execute('DELETE FROM page WHERE presenid = ?', (presenid,))
        shutil.rmtree(dir_path)

    # プレゼン一覧画面へ遷移する
    return show_list(db)


@route('/api/presen_info', method='GET')
def get_preseninfo(db):
    '''プレゼン情報取得API'''

    res_presens = []

    # プレゼンに関する情報を取得
    query = '''
            SELECT
                presen.id AS presenid,
                presen.title,
                page.id AS pageid,
                page.saytext,
                page.pageno,
                page.filename
            FROM
                presen
                LEFT OUTER JOIN page
                    ON presen.id = page.presenid
            ORDER BY
                presen.id, presen.createdtimestamp, page.pageno
            ;'''

    rows = db.execute(query)

    # presenid ごとに dict を作成
    for presenid, grouped_rows_iter in groupby(rows, key=itemgetter(0)):  # row[0](presenid)をキーにして、取得した情報をまとめてから処理をします
        presen = {}
        grouped_rows = list(grouped_rows_iter)
        presen['id'] = presenid
        presen['title'] = grouped_rows[0][1]
        presen['pages'] = []

        for row in grouped_rows:
            page = {}
            page['id'] = row[2]
            page['saytext'] = row[3]
            page['pageno'] = row[4]
            page['filename'] = row[5]
            page['presenid'] = presenid
            if page['id']:
                presen['pages'].append(page)

        res_presens.append(presen)

    # dict オブジェクトを json 文字列に変換してレスポンスを行う
    body = json.dumps({'presens': res_presens})
    res = HTTPResponse(status=200, body=body)
    res.set_header('Content-Type', 'application/json')

    return res


@route('/api/dl_file', method='GET')
def get_images():
    '''プレゼン登録画像取得API'''

    base_dir = './'
    src_dir = UPLOAD_DIR
    zip_name = 'presen_images.zip'
    save_dir = './temp'

    zip_file_path = os.path.join(save_dir, zip_name)

    if not os.path.isdir(save_dir):
        os.mkdir(save_dir)

    # 登録したプレゼン画像を全て含む zip ファイルを作成
    with zipfile.ZipFile(zip_file_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        os.chdir(base_dir)
        for root, dirs, files in os.walk(src_dir):
            for _file in files:
                filename = os.path.join(root, _file)
                arcname = os.path.join(root.split(os.path.sep)[-1], _file)
                zf.write(filename, arcname)

    return static_file(filename='presen_images.zip', root=save_dir, download=True)


@route('/static/<filename:path>')
def serve_static(filename):
    '''js, css, 画像などの静的ファイルを返す'''

    return static_file(filename, root=STATIC_DIR)


@route('/presen_images/<filename:path>')
def serve_images(filename):
    ''' プレゼン用画像を返す'''

    return static_file(filename, root=UPLOAD_DIR)


if __name__ == '__main__':

    # 初回起動時のDBセットアップ
    with open('./schema.sql', 'r') as schema, sqlite3.connect('./peppre.db') as conn:
        conn.executescript(schema.read())

    # bottle-sqlite をセットアップ
    install(SQLitePlugin(dbfile='./peppre.db'))

    # プレゼン画像保存ディレクトリを作成
    if not os.path.isdir(UPLOAD_DIR):
        os.mkdir(UPLOAD_DIR)

    # LAN 内からのリクエストを受け付けるため host=0.0.0.0 を指定
    run(host='0.0.0.0', port=8000, debug=True)
