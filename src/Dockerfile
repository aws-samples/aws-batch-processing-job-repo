FROM python

COPY batch_processor.py /


RUN pip install --upgrade pip && \
    pip install boto3 && \
    pip install boto 

RUN pwd
RUN ls

CMD ["python", "batch_processor.py"]