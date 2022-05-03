FROM tiangolo/uwsgi-nginx-flask:python3.9

ADD . /app

RUN pip install --no-cache-dir flask_cors dapr

RUN cp /app/app.py /app/main.py
RUN rm /app/app.py