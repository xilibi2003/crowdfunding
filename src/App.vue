<template>
  <div id="app">
    <CrowdFund/>
  </div>
</template>

<script>
import CrowdFund from './components/CrowdFund.vue'

export default {
  name: 'app',
  components: {
    CrowdFund
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 30px;
}
</style>
