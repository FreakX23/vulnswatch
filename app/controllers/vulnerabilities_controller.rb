class VulnerabilitiesController < ApplicationController
  before_action :set_vulnerability, only: [:show, :edit, :update, :destroy]

  # GET /vulnerabilities
  # GET /vulnerabilities.json
  def index
    # TODO:  This method shall be split in many!!
    # TODO: This method should go into relevant vulnerability model

    # First we do everything in the database
  
    # prefilter on fields
    @vulnerabilities = Vulnerability.filter(filtering_params) 

    # fulfil search
    if params[:search].present?
      conditions =['']
      params[:search].split(/\s+/).each do |term|
        term.downcase!
        newpart = '(LOWER(summary) LIKE ? OR LOWER(name) LIKE ? OR LOWER(affected_system) LIKE ?)'
        conditions[0] =  conditions[0].empty? ? newpart : conditions[0] + ' AND ' + newpart
        conditions.push "%#{term}%"
        conditions.push "%#{term}%"
        conditions.push "%#{term}%"
      end      
      @vulnerabilities = @vulnerabilities.where(conditions)
    end

    # sort
    case sorting_param
      when 'reaction'
        #pass : we can not sort on reaction yet
      when nil
        #pass : no sorting wanted
      else
        @vulnerabilities = @vulnerabilities.order(sorting_param.to_sym => sorting_way_param)
    end

    # Second in-memory procedures might start
    relevance = relevance_filter_params
    if relevance.has_key?(:project)
      # here we do relevance sorting
    end
    
    # finally paginate
    @vulnerabilities = @vulnerabilities.paginate(page: params[:page])
  end

  # GET /vulnerabilities/nvd
  def nvd
    Vulnerability.load_new_vulnerabilities_from_nvd()
    flash[:notice] = "Vulnerabilities Updated from NVD"
    redirect_to vulnerabilities_path
  end


  # GET /vulnerabilities/nvd_load_year/:year
  def nvd_load_year
    year = params[:year]
    year = year.to_i unless year.nil?
    if year.nil? or ! ( year.class == Fixnum ) or ! ( 2012 <= year and year <= Date.today.year.to_i)
      flash[:alert] = "Year was not properly specified"
    else
      flash[:notice] = "Vulnerabilities for year #{year} loaded from NVD"
      Vulnerability.load_vulnerabilities_from_nvd_for_year(year)
    end
    redirect_to vulnerabilities_path
  end


  # GET /vulnerabilities/1
  # GET /vulnerabilities/1.json
  def show
  end

  # GET /vulnerabilities/new
  def new
    @vulnerability = Vulnerability.new
  end

  # GET /vulnerabilities/1/edit
  def edit
    render 'change_affected_system'
  end

  # POST /vulnerabilities
  # POST /vulnerabilities.json
#  def create
#    @vulnerability = Vulnerability.new(vulnerability_params)
#
#    respond_to do |format|
#      if @vulnerability.save
#        format.html { redirect_to @vulnerability, notice: 'Vulnerability was successfully created.' }
#        format.json { render :show, status: :created, location: @vulnerability }
#      else
#        format.html { render :new }
#        format.json { render json: @vulnerability.errors, status: :unprocessable_entity }
#      end
#    end
#  end

  # PATCH/PUT /vulnerabilities/1
  # PATCH/PUT /vulnerabilities/1.json
  def update
    respond_to do |format|
      if @vulnerability.update(vulnerability_params)
        format.html { redirect_to @vulnerability, notice: 'Vulnerability was successfully updated.' }
        format.json { render :show, status: :ok, location: @vulnerability }
      else
        format.html { render 'change_affected_system' }
        format.json { render json: @vulnerability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vulnerabilities/1
  # DELETE /vulnerabilities/1.json
  def destroy
    @vulnerability.destroy
    respond_to do |format|
      format.html { redirect_to vulnerabilities_url, notice: 'Vulnerability was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vulnerability
      @vulnerability = Vulnerability.find_by(id: params[:id])
      if @vulnerability.nil? 
        flash[:alert] = "Invalid vulnerability specified"
        redirect_to vulnerabilities_path
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vulnerability_params
      params.require(:vulnerability).permit(:affected_system)
    end

    def filtering_params
      params.permit(:name, :summary, :affected_system)
    end

    def relevance_filter_params
      params.permit(:project)
    end
    
    def allowed_sorting_params
      return ['name', 'modified', 'affected_system', 'reaction']
    end

    def sorting_way_param
      par = params.permit(:sorting_way)
      if par.has_key?(:sorting_way)
        case par[:sorting_way]
          when 'asc'
            return :asc
          when 'desc'
            return :desc
        end
      end
      return :desc
    end
        
    def sorting_param
      par = params.permit(:sorting)
      if par.has_key?(:sorting) and (allowed_sorting_params.include? par[:sorting])
        return par[:sorting]
      end
      return nil      
    end

end
