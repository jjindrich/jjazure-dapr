from email.policy import strict
from flask import Flask, request, render_template, jsonify
from flask_cors import CORS
import os
import json
import socket
import sys
import time
from dapr.clients import DaprClient

app = Flask(__name__)
CORS(app)

# Change title to host name to demo NLB
title = 'UI Python Article voting running on ' + socket.gethostname()
likecount = 0

@app.route('/', methods=['GET', 'POST'])

def index():

    if request.method == 'GET':
        # call app-votes hello method
        hello()
        return render_template("index.html", value1=likecount, title=title)

    elif request.method == 'POST':

        if request.form['vote'] == 'vote':            
            vote(request.form['articleid'], request.form['userid'])
            return render_template("index.html", value1=likecount, title=title)

        if request.form['vote'] == 'likecount':            
            likecount2 = get_count(request.form['articleid'])
            return render_template("index.html", value1=likecount2, title=title)

# Call app-votes Hello method
def hello():
    with DaprClient() as d:            
        resp = d.invoke_method('app-votes', 'hello', data=b'')
        print(resp, flush=True)

# Call app-votes Like method
def vote(articleid: str, userid: str):
    with DaprClient() as d:                    
        req_data = {
            'articleid': articleid,
            'userid': userid
        }
        print(req_data, flush=True)        
        resp = d.invoke_method('app-votes', 'like', data=json.dumps(req_data), http_verb='post')
        print(resp, flush=True)

# Call app-articles Get count method
def get_count(articleid: str):
    with DaprClient() as d:                    
        resp = d.invoke_method('app-articles', f"count/{articleid}", data=b'', http_verb="get")        
        print(resp.text(), flush=True)        
        return resp.text()

if __name__ == "__main__":
    app.run()
