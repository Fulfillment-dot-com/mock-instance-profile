FROM python:3.11-alpine3.17

WORKDIR /usr/src/app

RUN apk add curl py3-pip git bash && \
    python3 -m ensurepip && \
        pip3 install -U --no-cache-dir \
            pip \
            wheel

RUN curl -Lo ec2-metadata-mock https://github.com/aws/amazon-ec2-metadata-mock/releases/download/v1.11.2/ec2-metadata-mock-`uname | tr '[:upper:]' '[:lower:]'`-amd64 && \
    chmod +x ec2-metadata-mock && \
    cp ec2-metadata-mock /bin && \
    cp ec2-metadata-mock /usr/bin

COPY . .

RUN pip3 install -r requirements.txt

CMD ["/usr/src/app/run.sh"]