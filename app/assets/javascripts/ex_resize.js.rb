class Element
  def ex_resize(&block)
    %x{
      var height = self.outerHeight();
      var width = self.outerWidth();
      setInterval(function(){
        var h = self.outerHeight();
        var w = self.outerWidth();
        if (height != h || width != w) {
          #{block.call if block_given?};
          height = h;
          width = w;
        }
      }, 1000);
    }
    block
  end
end
