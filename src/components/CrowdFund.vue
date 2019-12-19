<template>
<div class="content">
  <h3> 新书众筹</h3>
  <span>以最低的价格获取我的新书 </span>

  <!-- 众筹的总体状态  -->
  <div class="status">
    <div v-if="!closed">已众筹资金：<b>{{ total }} ETH </b></div>
    <div v-if="closed"> 众筹已完成 </div>
    <div>众筹截止时间：{{ endDate }}</div>
  </div>

  <!-- 当读者参与过，显示如下div  -->
  <div v-if="joined" class="card-bkg">
    <div class="award-des">
      <span> 参与价格 </span>
      <b> {{ joinPrice }} ETH </b>
    </div>

    <button :disabled="closed" @click="withdraw">赎回</button>
  </div>

  <!-- 当读者还未参与时，显示如下div  -->
  <div v-if="!joined" class="card-bkg">
    <div class="award-des">
      <span> 当前众筹价格 </span>
      <b> {{ price }} ETH </b>
    </div>

    <button :disabled="closed" @click="join">参与众筹</button>
  </div>

  <!--  如果是创作者，显示 -->
  <div v-if="isAuthor">
    <button :disabled="closed" @click="withdrawFund"> 提取资金</button>
  </div>

</div>
</template>

<script>
import Web3 from "web3";
import contract from "truffle-contract";
import crowd from '../../build/contracts/Crowdfunding.json';

export default {
  name: 'CrowdFund',
  data() {
    return {
      price: null,
      total: 0,
      closed: true,
      joinPrice: null,
      joined: false,
      endDate: "2019-08-20",
      isAuthor: true,
    }
  },

  async created() {
    await this.initWeb3Account()
    await this.initContract()
    await this.getCrowdInfo()
  },

  methods: {

    async initWeb3Account() {
      if (window.ethereum) {
        this.provider = window.ethereum;
        try {
          await window.ethereum.enable();
        } catch (error) {
          //   console.log("User denied account access");
        }
      } else if (window.web3) {
        this.provider = window.web3.currentProvider;
      } else {
        this.provider = new Web3.providers.HttpProvider("http://127.0.0.1:7545");
      }
      this.web3 = new Web3(this.provider);

      this.web3.eth.getAccounts((err, accs) => {
        if (err != null) {
          //   console.log("无法获取账号， 是否安装了 Metamask");
          return;
        }

        if (accs.length === 0) {
          //   console.log("无法获取账号，Metamask 时候正确配置.");
          return;
        }

        this.account = accs[0]
      })
    },

    async initContract() {
      const crowdContract = contract(crowd)
      crowdContract.setProvider(this.provider)
      this.crowdFund = await crowdContract.deployed()
    },

    getCrowdInfo() {

      this.web3.eth.getBalance(this.crowdFund.address).then(
        r => {
          this.total = this.web3.utils.fromWei(r)
        }
      )

      this.crowdFund.joined(this.account).then(
        r => {
          if (r > 0) {
            this.joined = true
            this.joinPrice = this.web3.utils.fromWei(r)
          }
        }
      )

      this.crowdFund.closed().then(
        r => this.closed = r
      )

      this.crowdFund.price().then(
        r => this.price = this.web3.utils.fromWei(r)
      )

      this.crowdFund.endTime().then(r => {
        var endTime = new Date(r * 1000)
        this.endDate = endTime.toLocaleDateString().replace(/\//g, "-") + " " + endTime.toTimeString().substr(0, 8);
      })

      this.crowdFund.author().then(r => {
        if (this.account == r) {
          this.isAuthor = true
        } else {
          this.isAuthor = false
        }
      })

    },

    join() {
      this.web3.eth.sendTransaction({
        from: this.account,
        to: this.crowdFund.address,
        value: this.web3.utils.toWei(this.price)
      }).then(() =>
        this.getCrowdInfo()
      )
    },

    withdraw() {
      this.crowdFund.withdraw({
        from: this.account
      }).then(() => {
        this.getCrowdInfo()
      })
    },

    withdrawFund() {
      this.crowdFund.withdrawFund({
        from: this.account
      }).then(() => {
        this.getCrowdInfo()
      })
    }

  }
}
</script>

<style scoped>
.content {
  font-size: 187 px;
}

.status {
  margin: 20px;
}

.card-bkg {
  margin: 10px;
  display: flex;
  justify-content: space-between;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, .12), 0 0 6px rgba(0, 0, 0, .04);
  border-radius: 5px;
  padding: 11px;
}

.award-des {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.award-des span {
  font-size: 12px;
}

.award-des b {
  font-size: 16px;
}

button {
  display: inline-block;
  line-height: 1;
  border-radius: 4px;
  padding: 12px 20px;
  white-space: nowrap;
  font-weight: 500;
  border: 1px solid #dcdfe6;
}
</style>
