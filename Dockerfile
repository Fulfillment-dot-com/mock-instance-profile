FROM python:3.11-alpine3.17

WORKDIR /usr/src/app

COPY . .

RUN apk add --no-cache bash && \
    apk add --no-cache --virtual=build-deps \
    curl && \
    curl -Lo ec2-metadata-mock https://github.com/aws/amazon-ec2-metadata-mock/releases/download/v1.11.2/ec2-metadata-mock-`uname | tr '[:upper:]' '[:lower:]'`-amd64 && \
    chmod +x ec2-metadata-mock && \
    cp ec2-metadata-mock /usr/bin && \
    rm ec2-metadata-mock && \
    apk del --purge \
        build-deps

RUN python3 -m ensurepip && \
    pip3 install -r requirements.txt

CMD ["/usr/src/app/run.sh"]