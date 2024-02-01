extern crate dsn_e2e_tests;

use std::time::Duration;

use dsn_e2e_tests::node::DsnNode;
use dsn_rpc::proto;
use log::LevelFilter;
use tokio::time::sleep;

#[tokio::test]
async fn test_single_dsn_node_fifo() -> anyhow::Result<()> {
    env_logger::builder()
        .filter(None, LevelFilter::Debug)
        .init();

    let mut node = DsnNode::run();
    let mut client = node.connect().await;

    for i in 0..30u8 {
        client
            .submit_transaction(proto::Transaction {
                transaction: vec![i],
            })
            .await?;
        sleep(Duration::from_millis(100)).await;
    }

    sleep(Duration::from_millis(500)).await;
    let head = client
        .get_pre_blocks_head(proto::Empty {})
        .await?
        .into_inner();
    assert_ne!(0, head.id);

    let mut pre_blocks = client
        .live_query_pre_blocks(proto::PreBlocksRequest { from_id: 0 })
        .await?
        .into_inner();

    let mut idx = 0u8;
    loop {
        let pre_block = pre_blocks.message().await?.unwrap();
        for tx in pre_block.transactions {
            assert_eq!(vec![idx], tx.transaction);
            idx += 1;
        }
        if pre_block.header.unwrap().id == head.id {
            break;
        }
    }
    assert_eq!(30, idx);

    Ok(())
}
