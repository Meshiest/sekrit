(function(){

var app = angular.module('app', [])

app.controller('AppCtrl', function($scope, $http){
  
  $scope.getPosts = function() {
    $http.get('/posts').success(function(posts) {
      $scope.posts = posts
      console.log("POSTS",posts)
    })
  }

  $scope.getComments = function(id) {
    $http.get('/comments', {params: {id: id}}).success(function(comments) {
      $scope.comments[id] = comments
    })
  }

  $scope.getPosts()

  $scope.writing = false
  $scope.viewing = false
  $scope.comments = {}

  $scope.topBtnClick = function() {
    if($scope.viewing) {
      $scope.viewing = false
    }
    $scope.getPosts()
  }

  $scope.viewPost = function(post) {
    console.log('viewing ',post.id.$oid)
    $scope.viewing = post.id.$oid
    $scope.selectedPost = post
    $scope.getComments(post.id.$oid)
  }

  $scope.closePost = function() {
    $scope.writing = false
  }

  $scope.createPost = function() {
    $scope.writing = true
    $scope.question = ''      
  }

  $scope.submit = function() {
    var question = $scope.question
    console.log('trying to submit',question)
    if(question.length < 10)
      return
    console.log('Sending',question)
    if($scope.viewing) {
      $http({
        method: 'POST',
        url: '/answer',
        params: {
          'msg': question,
          'id': $scope.viewing
        }
      }).success(function(){
        $scope.getComments($scope.viewing)
      })
    } else {
      $http({
        method: 'POST',
        url: '/post',
        params: {
          'msg': question
        }
      }).success(function(){
        $scope.getPosts()
      })
    }
    $scope.writing = false
  }
})

})()