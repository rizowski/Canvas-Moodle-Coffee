
var settings = {
  assignments : {
    color: false,
    displayLate : false,
    displayRange: "7 days"
  },
  courses : {
    gradeFormat : 3
  }
}

describe("Saving Settings", function(){
  describe("Sync", function(){


  });

  describe("local", function(){
    it("Saves the canvas key properly with spaces", function(){
      CanvasExtension.prototype.settings.saveCanvasKey("1~ Hello");

      CanvasExtension.prototype.settings.getCanvasKey(function(key){
        expect(key).toEqual("1~Hello");
      });
    });
  });
});


describe("Loading Settings",function(){
  describe("Sync", function(){
    it("loads the canvas key properly", function(){
      // extension.prototype.settings.loadSettings();
    });
  });

  describe("local", function(){

  });
});
