use Test::Most;

use Paws;
use Paws::Credential::None;
use Paws::Kinesis::MemoryCaller;
use Paws::Kinesis::PutRecordsRequestEntry;

my $kinesis = Paws->service('Kinesis',
    region      => 'N/A',
    credentials => Paws::Credential::None->new(),
    caller      => Paws::Kinesis::MemoryCaller->new(),
);

$kinesis->CreateStream(StreamName => "my_stream", ShardCount => 1);

my $describe_stream_output = $kinesis->DescribeStream(
    StreamName => "my_stream",
);

my $shard_id = $describe_stream_output->StreamDescription->Shards->[0]->ShardId;

$kinesis->PutRecords(
    Records => [
        Paws::Kinesis::PutRecordsRequestEntry->new(
            Data => "1st Message",
            PartitionKey => "olympics",
        ),
        Paws::Kinesis::PutRecordsRequestEntry->new(
            Data => "2nd Message",
            PartitionKey => "olympics",
        ),
    ],
    StreamName => "my_stream",
);

my $shard_iterator = $kinesis->GetShardIterator(
    ShardId           => $shard_id,
    ShardIteratorType => "TRIM_HORIZON",
    StreamName        => "my_stream",
)->ShardIterator;
ok ($shard_iterator, "got a new shard_iterator ($shard_iterator)");

my $get_records_output = $kinesis->GetRecords(ShardIterator => $shard_iterator);
my $next_shard_iterator = $get_records_output->NextShardIterator;
my $records = $get_records_output->Records;

ok($next_shard_iterator, "got a new shard_iterator ($next_shard_iterator)");
is scalar @$records, 2, 'got two records';
is $records->[0]->Data, "1st Message", "got correct data";
is $records->[1]->Data, "2nd Message", "got correct data";

done_testing;
