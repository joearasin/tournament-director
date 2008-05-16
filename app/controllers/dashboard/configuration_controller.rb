class Dashboard::ConfigurationController < DashboardController

  before_filter :load_configuration

  def index
    redirect_to :action => "edit_tournament"
  end

  def load_tournament
    session[:tournament_id] = params['id']
    @tournament = Tournament.find(params['id'])
    load_tournament_database(@tournament)
    redirect_to :action => "edit_tournament"
  end

  def new_tournament
    render :action => "_new_tournament"
  end
  
  def create_tournament
    @tournament = Tournament.create(:name => params['name'], :database => params['database'])
    session[:tournament_id] = @tournament.id
    load_tournament_database(@tournament)
    redirect_to :action => "edit_tournament"
  end

  def edit_tournament
    @brackets = Bracket.find(:all, :order => "ordering, name")
    @all_tournaments = Tournament.find(:all, :order => "id desc")
    @all_tournaments.delete(@tournament)
  end
  
  def save_tournament
    @tournament.update_attributes(params['tournament'])
    QuestionType.configure_for_power(@tournament.power)
    @tournament.bracketed = false if (params['bracket_names'].nil?)
    if @tournament.bracketed?
      brackets_to_delete = Bracket.find(:all)
      for name in params['bracket_names']
        next if name.empty?
        bracket = Bracket.find_or_create_by_name(name)
        brackets_to_delete.delete(bracket)
      end
      brackets_to_delete.each {|b| b.destroy}
    else
      Bracket.destroy_all
    end
    @tournament.bracketed = false if Bracket.count == 0
    @tournament.save
    flash[:notice] = "Changes saved."
    redirect_to :action => "edit_tournament"
  end
  
  def edit_schools
  	@other_schools = School.find :all
  	@tournament.schools.each do |s|
  		@other_schools.delete(s)
  	end
  	
  	begin
  		@school = School.find(params[:id])
  	rescue ActiveRecord::RecordNotFound
  		@school = School.new
  	end
  end
  
  def save_school
  	begin
  		sch = School.find(params[:id])
  	rescue ActiveRecord::RecordNotFound
  		sch = School.new
  	end
  	sch.update_attributes(params[:school])
  	sch.save
  	flash[:notice] = "School saved."
  	redirect_to :action => "edit_schools"
  end
  
  def add_tournament_school
  	begin
  	  @tournament.schools<< School.find(params[:id])
  	  flash[:notice] = "School added."
  	rescue ActiveRecord::RecordNotFound
  	end
  	redirect_to :action => "edit_schools"
  end
  
  def rm_tournament_school
  	begin
  	  @tournament.schools.delete(School.find(params[:id]))
  	  flash[:notice] = "School removed."
  	rescue ActiveRecord::RecordNotFound
  	end
  	redirect_to :action => "edit_schools"
  end

  def edit_teams
    if @tournament.nil?
      redirect_to :action => 'edit_tournaments'
    end
    
    begin
    	@team = @tournament.teams.find(params[:id])
    rescue ActiveRecord::RecordNotFound
    	@team = @tournament.teams.build
    end
  end

  def save_team
	begin
		team = @tournament.teams.find(params[:id])
	rescue ActiveRecord::RecordNotFound
		team = @tournament.teams.build
	end
	team.update_attributes(params[:team])
	team.save
	flash[:notice] = "Team saved."
	redirect_to :action => 'edit_teams'
  end
  
  def save_players
  	team = Team.find(params[:id], :include => :players)
  	players_to_delete = team.players.dup
  	for i in 0..params[:player_names].length
  		name = params[:player_names][i]
		next if name.nil? or name.empty?
		player = team.players.find(:first, :conditions => ['name = ?', name]) || team.players.build(:name => name)
		player.year = params[:player_years][i]
		player.future_school = params[:player_schools][i]
		player.save
		players_to_delete.delete(player)
  	end
  	players_to_delete.each{|p| p.destroy }
  	flash[:notice] = "Player names saved."
  	redirect_to :action => "edit_teams"
  end

end
