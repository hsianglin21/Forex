# Grid Search

# Importing the libraries
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.grid_search import GridSearchCV

# Create a Helper Class to apply Grid Search to find the best model and the best parameters
class EstimatorSelectionHelper:
    def __init__(self, models, params):
        if not set(models.keys()).issubset(set(params.keys())):
            missing_params = list(set(models.keys()) - set(params.keys()))
            raise ValueError("Some estimators are missing parameters: %s" % missing_params)
        self.models = models
        self.params = params
        self.keys = models.keys()
        self.grid_searches = {}
    
    def fit(self, X, y, cv=10, n_jobs=1, verbose=1, scoring = None, refit=False):
        for key in self.keys:
            print("Running GridSearchCV for %s." % key)
            model = self.models[key]
            params = self.params[key]
            gs = GridSearchCV(model, params, cv=cv, n_jobs=n_jobs, 
                              verbose=verbose, scoring=scoring, refit=refit)
            gs.fit(X,y)
            self.grid_searches[key] = gs    
    
    def score_summary(self, sort_by='mean_score'):
        def row(key, scores, params):
            d = {
                 'estimator': key,
                 'min_score': min(scores),
                 'max_score': max(scores),
                 'mean_score': np.mean(scores),
                 'std_score': np.std(scores),
            }
            return pd.Series(dict(params.items() | d.items()))
                      
        rows = [row(k, gsc.cv_validation_scores, gsc.parameters) 
                     for k in self.keys
                     for gsc in self.grid_searches[k].grid_scores_]
        df = pd.concat(rows, axis=1).T.sort_values([sort_by], ascending=False)
        
        columns = ['estimator', 'min_score', 'mean_score', 'max_score', 'std_score']
        columns = columns + [c for c in df.columns if c not in columns]
        
        return df[columns]


# Importing the dataset
dataset = pd.read_csv('2017ForexZigzagMin5Data.csv')
X = dataset.iloc[:, 0:1].values
y = dataset.iloc[:, 4].values


#Define the models and their model parameters
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.linear_model import LinearRegression, Ridge, Lasso
from sklearn.svm import SVR
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor



models = { 
    'LinearRegression': LinearRegression(),
    'Ridge': Ridge(),
    'Lasso': Lasso(),
    'SVR': SVR(),
    'DecisionTree': DecisionTreeRegressor(random_state = 0),
    'RandomForest': RandomForestRegressor(random_state = 0),
}

params = { 
    'LinearRegression': { },
    'Ridge': { 'alpha': [0.1, 1.0] },
    'Lasso': { 'alpha': [0.1, 1.0] },
    'SVR': {'kernel': ['rbf'], "C": [1e0, 1e1, 1e2, 1e3], 'gamma': np.logspace(-2, 2, 5) },
    'DecisionTree': {'min_samples_split' : list(range(10,200,50)),'max_depth': list(range(1,10,2)) },
    'RandomForest': {   'n_estimators': [10, 100],'max_features': ['auto', 'sqrt', 'log2']},
}


# Fit the models and parameters to Grid Search
helper = EstimatorSelectionHelper(models, params)
helper.fit(X, y, n_jobs=1)

#Print the Report Summary, the top row is the best score and best parameters
helper.score_summary()
results = helper.score_summary()
