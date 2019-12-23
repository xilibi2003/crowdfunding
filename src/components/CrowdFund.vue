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

  <!--  当读者还未参与时，显示如下div  -->
  <div v-if="!joined" class="card-bkg">
    <div class="award-des">
      <span> 当前众筹价格 </span>
      <b> {{ price }} ETH </b>
    </div>

    <button :disabled="closed" @click="join">参与众筹</button>
  </div>

  <!--  如果是创作者，显示 -->
  <div class="box" v-if="isAuthor">
    <div >
      <p v-bind:key="item" v-for="item in joinList" >
        <label> 地址：{{ item.address.substring(0, 30) + "..."  }} </label>
        金额：<b> {{ item.price }} </b>
      </p>
    </div>

    <button :disabled="closed" @click="withdrawFund"> 提取资金</button>
  </div>

</div>
</template>

<script>
import Web3 from "web3";
import contract from "truffle-contract";
import crowd from '../../build/contracts/Crowdfunding.json';
import axios from 'axios'

export default {
  name: 'CrowdFund',
  // 定义上面HTML模板中使用的变量
  data() {
    return {
      price: null,
      total: 0,
      closed: true,
      joinPrice: null,
      joined: false,
      endDate: "null",
      isAuthor: true,

      joinList: [],
    }
  },

    // 当前Vue组件被创建时回调的hook 函数
  async created() {
    await this.initWeb3Account()
    await this.initContract()
    await this.getCrowdInfo()
    this.getJoins()
  },

  methods: {

    // 初始化 web3及账号
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

      this.web3.eth.getAccounts().then(accs  => {
        this.account = accs[0]
      })
    },

    //  初始化合约实例
    async initContract() {
      const crowdContract = contract(crowd)
      crowdContract.setProvider(this.provider)
      this.crowdFund = await crowdContract.deployed()
    },

    // 获取合约的状态信息
    async getCrowdInfo() {

      // 获取合约的余额
      this.web3.eth.getBalance(this.crowdFund.address).then(
        r => {
          this.total = this.web3.utils.fromWei(r)
        }
      )

      // 获取读者的参与金额， joined 在合约中是public 的状态变量，自动生成相应的访问器函数
      this.crowdFund.joined(this.account).then(
        r => {
          if (r > 0) {
            this.joined = true
            this.joinPrice = this.web3.utils.fromWei(r)
          }
        }
      )

     // 获取合约的关闭状态
      this.crowdFund.closed().then(
        r => this.closed = r
      )

      // 获取当前的众筹价格
      this.crowdFund.price().then(
        r => this.price = this.web3.utils.fromWei(r)
      )

      // 获取众筹截止时间
      this.crowdFund.endTime().then(r => {
        var endTime = new Date(r * 1000)
        // 把时间戳转化为本地时间
        this.endDate = endTime.toLocaleDateString().replace(/\//g, "-") + " " + endTime.toTimeString().substr(0, 8);
      })

      // 获取众筹创作者地址
      this.crowdFund.author().then(r => {
        if (this.account == r) {
          this.isAuthor = true
        } else {
          this.isAuthor = false
        }
      })

    },

    // 读者点击参与众筹时调用
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
    },

    // 获取众筹列表
    getJoins() {
      axios.get('http://localhost:3000/joins')
        .then(response => {
          this.joinList = response.data
        })
        .catch(function (error) { // Ajax请求失败处理
          console.log(error);
        });
    },

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

.box {
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, .12), 0 0 6px rgba(0, 0, 0, .04);
  border-radius: 5px;
  padding: 11px;
  margin: 10px;
}


</style>
