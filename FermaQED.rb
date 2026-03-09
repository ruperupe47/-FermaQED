class FermaQED

  require 'strscan'
  def initialize
     @debug = false
     @debug_evsl = false
     @x = 0

     # 初期化
     @arry_hash = {}

     # コードの取得
     if ARGV[0]
       # ファイルが存在しない例外処理
       begin
         @file_name = ARGV[0]
         file = open(@file_name)
         exp = file.read
         file.close
       rescue
         puts $!.to_s
         exit
       end
     end

     @scanner = StringScanner.new(exp)

     tree = parse()

     if @debug == true
       print tree
       puts "意味解析スタート"
     end
     eval_mein(tree)
  end


  keywords = {
    '+'=>:add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '(' => :left_parn,
    ')' => :right_parn
  }


  # 意味解析
  def eval_mein(exp)
    exp.each_with_index do |value, index|
      if @debug_evsl == true
        @x = @x + 1
        puts @x
        print exp[index]
        puts 
      end

      # puts  exp[index][0]
      # 文解析
      case exp[index][0]
      when :substitution_writings
        var = exp[index][1].to_s
        num =  eval(exp[index][2])
        @arry_hash[var] = num

      when :if_writings
        # print exp[index][1]
        if_eval(exp[index])

      when :while_writings
        while_eval(exp[index])
      
      when :def_print_writings
        num =  eval(exp[index][1])
        puts num

      when :def_Ferma_writings
        print @arry_hash
        puts ""
        
      when :expression_writings
        num =  eval(exp[index][1])
      end


    end

  end


  # 計算用_eval
  def eval(exp)
    if exp.is_a?(Array) && exp.length == 1
       exp = @arry_hash[exp[0].to_s] 
    end

    if exp.instance_of?(Array)
      case exp[0]
      when :add
        return eval(exp[1]) + eval(exp[2])
      when :sub
        return eval(exp[1]) - eval(exp[2])
      when :mul
        return eval(exp[1]) * eval(exp[2])
      when :div
        return eval(exp[1]) / eval(exp[2])
      end
    else
      return exp
    end
  end


  # if文_eval
  def if_eval(exp)
    exp.shift
    bool = false

    exp.each_with_index do |value, index|
      case exp[index][0][0]
      when :def_big
        bool = func_big(exp[index][0])
      when :def_small
        bool = func_small(exp[index][0])
      when :def_equal
        bool = func_equal(exp[index][0])
      when :elnil
        bool = true
      end

      if bool == true
        # print exp[index][1]
        eval_mein([exp[index][1]])
        break
      end
    end
  end


  # while文_eval
  def while_eval(exp)
    exp.shift
    bool = false

    case exp[0][0]
    when :def_big
      bool = func_big(exp[0])
    when :def_small
      bool = func_small(exp[0])
    when :def_equal
      bool = func_equal(exp[0])
    end

    while bool == true
      eval_mein([exp[1]])
      case exp[0][0]
      when :def_big
        bool = func_big(exp[0])
      when :def_small
        bool = func_small(exp[0])
      when :def_equal
        bool = func_equal(exp[0])
      end
    end

  end


  # 各種関数処理
  def func_big(exp)
    x1 = eval(exp[1])
    x2 = eval(exp[2])
    if x1 > x2
      bool = true
    else
      bool = false
    end
    return bool
  end

  def func_small(exp)
    x1 = eval(exp[1])
    x2 = eval(exp[2])
    if x1 < x2
      bool = true
    else
      bool = false
    end
    return bool
  end

  def func_equal(exp)
    x1 = eval(exp[1])
    x2 = eval(exp[2])
    if x1 == x2
      bool = true
    else
      bool = false
    end
    return bool
  end




  # 構文解析器
  def parse()
    if @debug == true
      puts "p1"
    end
    sentence()
  end
  
  def sentence()
    codes = []
    until @scanner.eos?
      if @debug == true
        puts "p2"
      end

      @scanner.skip(/\s+/)
      if @scanner.eos?
        break
      end


      codes.append(literature())
    end
    return codes
  end

  
  def literature()
    token = get_token()
    if token == :left_arry
      if @debug == true
        puts "p3_1"
      end

      token = get_token()
      unless token.to_s =~ /\A\d+\z/
        raise Exception, "構文エラー"
      end
      index = token.to_i
      t = get_token()
      unless t == :right_arry
        raise Exception,"構文エラー"
      end     
      t = get_token()
      unless t == :substitution
        raise Exception,"構文エラー"
      end    
      formula = expression()
      t = get_token()
      unless t == :QED
        raise Exception,"終端エラー"
      end          
      result = [:substitution_writings,index,formula]


    elsif token == :if
      if @debug == true
        puts "p3_2"
      end

      box = [:if_writings]
      func = func_parse()
      t = get_token()
      unless t == :colon
        raise Exception,"構文エラー"
      end
      formula = literature()
      box.append([func,formula])
      token = get_token() 

      while token == :elif
        if @debug == true
          puts "p3_2_1"
        end

        func = func_parse()
        t = get_token()
        unless t == :colon
          raise Exception,"構文エラー"
        end
        formula = literature()
        box.append([func,formula])
        token = get_token() 
      end

      if token == :else
        if @debug == true
          puts "p3_2_2"
        end

        t = get_token()
        unless t == :colon
          raise Exception,"構文エラー"
        end
        formula = literature()
        box.append([[:elnil],formula])
        token = get_token() 
      end

      unless token == :QED
        raise Exception,"終端エラー"
      end
      result = box


    elsif token == :while
        if @debug == true
          puts "p3_3"
        end

        func = func_parse()  
        t = get_token() 
        unless t == :colon
          raise Exception,"構文エラー"
        end
        formula = literature()
        result = [:while_writings,func,formula]
        token = get_token() 
        unless token == :QED
          raise Exception,"終端エラー"
        end

    elsif token == :def_print
        if @debug == true
          puts "p3_4"
        end

      formula = expression()
      token = get_token() 
      unless token == :right_parn
        raise Exception,"終端エラー"
      end
      token = get_token() 
      unless token == :QED
        raise Exception,"終端エラー"
      end
      result = [:def_print_writings, formula]

      elsif token == :def_Ferma
        if @debug == true
          puts "p3_4"
        end

      token = get_token() 
      unless token == :right_parn
        raise Exception,"終端エラー"
      end
      token = get_token() 
      unless token == :QED
        raise Exception,"終端エラー"
      end
      result = [:def_Ferma_writings, formula]
    

    else
      # 式
      if @debug == true
        puts "p3_0"
      end

      unget_token(token)
      result = [:expression_writings,expression()]
      t = get_token()
      unless t == :QED
        raise Exception,"終端エラー"
      end      
    end    


    return result
  end


  def func_parse()
    token = get_token()
    if token == :def_big or token == :def_small or token == :def_equal
      if @debug == true
        puts "p4_1"
      end

      x_num = expression()
      t = get_token()
      unless t == :comma
        raise Exception,"構文エラー"
      end
      y_num = expression()
      t = get_token()
      unless t == :right_parn
        raise Exception,"構文エラー"
      end
      result = [token,x_num,y_num]
    end
    return result
  end
  

  def expression()
    if @debug == true
      puts "p5"
    end

    result = term()
    token = get_token()
    while token == :add or token == :sub
      result = [token, result, term()]
      token = get_token()
    end
    # puts "[expression] = #{result.inspect}"
    unget_token(token)
    return result
  end

  def term()
    if @debug == true
      puts "p6"
    end

    result = factor()
    token = get_token()
    while token == :mul or token == :div
      result = [token, result, factor()]
      token = get_token()
    end
     
    # puts "[term] = #{result.inspect}"

    unget_token(token)
    return result
  end


  def factor()
    if @debug == true
      puts "p7"
    end

    token = get_token()
    if token.to_s =~ /\A\d+\z/
      if @debug == true
        puts "p7_1"
      end

      # puts "[factor] = #{token}"
      result = token.to_i
    elsif token == :left_parn
      # puts "[factor] ("
      result = expression()
      t = get_token()
      unless t == :right_parn
        raise Exception,"構文エラー"
      end
    elsif token == :left_arry
      # puts "[factor] ("
      token = get_token()
      result = [token.to_i]
      t = get_token()
      unless t == :right_arry
        raise Exception,"構文エラー"
      end
    else
      raise Exception, "構文エラー"
    end
    return result
  end


  def get_token()
    keywords = {
      # 計算用演算子
      '+'=>:add,
      '-' => :sub,
      '*' => :mul,
      '/' => :div,
      '(' => :left_parn,
      ')' => :right_parn,
      '[' => :left_arry,
      ']' => :right_arry,
      '=' => :substitution,
      ':' => :colon,
      ',' => :comma,

      # 予約語
      'if' => :if,
      'elif' => :elif,
      'else' => :else,
      'while' => :while,
      'QED' => :QED,

      # 比較用関数
      'large_comparison(' => :def_big,
      'small_comparison(' => :def_small,
      'equal_comparison(' => :def_equal,

      # 関数
      'print(' => :def_print,
      'Ferma(' => :def_Ferma
    }

    @scanner.skip(/\s+/)
    @scanner.skip(/\t+/)

    if val = @scanner.scan(/\d+/)
      return val
    end

    if sys = @scanner.scan(/\b(if|elif|else|while|QED)\b/)
      return keywords[sys]
    end

    if func = @scanner.scan(/print\(|large_comparison\(|small_comparison\(|equal_comparison\(|Ferma\(/)
      return keywords[func]
    end

    if op = @scanner.scan(/[\+\-\*\/\(\)\[\]\=\:\,]/)
      return keywords[op]
    end
  end


  # 触れない
  def unget_token(token)
    begin 
      @scanner.unscan
    rescue
    end
  end


end

fermaQED = FermaQED.new