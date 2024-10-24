import os
import time
import shutil
import numpy as np
import pandas as pd

np.set_printoptions(threshold=np.inf)

import torch
import torch.onnx
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import matplotlib.pyplot as plt

# Parameters
num_samples = 100000
steps = 10
epochs = 1000
patience = 50
threshold = 0.01
units = 3
LSTM_layers = 1
fc_layers = 1
learning_rate = 0.0001
batch_size = 64

# Set seed for reproducibility
seed = 5
np.random.seed(seed)
torch.manual_seed(seed)

def df_to_X_y(df, window_size=5):
    df_as_np = df.to_numpy()
    X, y = [], []
    for i in range(len(df_as_np)-window_size):
        X.append(df_as_np[i:i+window_size])
        y.append(df_as_np[i+window_size])
    return np.array(X), np.array(y)

def normalize_data(X, y):
    mean_X, std_X = np.mean(X, axis=0), np.std(X, axis=0)
    mean_y, std_y = np.mean(y, axis=0), np.std(y, axis=0)
    X = (X - mean_X) / std_X
    y = (y - mean_y) / std_y
    return X, y, mean_X, std_X, mean_y, std_y

def to_tensor(X, y):
    return torch.tensor(X, dtype=torch.float32), torch.tensor(y, dtype=torch.float32)

class LSTMModel(nn.Module):
    def __init__(self, input_dim, hidden_dim, output_dim, lstm_layers=1, fc_layers=1):
        super(LSTMModel, self).__init__()
        self.lstm = nn.LSTM(input_dim, hidden_dim, num_layers=lstm_layers, batch_first=True)
        self.fc_layers = nn.ModuleList([nn.Linear(hidden_dim, hidden_dim) for _ in range(fc_layers-1)])
        self.relu = nn.ReLU()
        self.fc_out = nn.Linear(hidden_dim, output_dim)
        
    def forward(self, x):
        _, (h_n, _) = self.lstm(x)
        h_n = h_n[-1]
        for fc in self.fc_layers:
            h_n = self.relu(fc(h_n))
        return self.fc_out(h_n)

def train_model(model, train_loader, val_loader, optimizer, criterion, epochs, patience, threshold):
    train_losses, val_losses = [], []
    best_val_loss = float('inf')
    epochs_without_improvement = 0

    plt.ion()
    fig, ax = plt.subplots()

    start_time = time.time()

    for epoch in range(epochs):
        model.train()
        train_loss = 0
        for X_batch, y_batch in train_loader:
            optimizer.zero_grad()
            y_pred = model(X_batch).squeeze()
            loss = criterion(y_pred, y_batch)
            loss.backward()
            optimizer.step()
            train_loss += loss.item()
        train_loss /= len(train_loader)
        train_losses.append(train_loss)

        model.eval()
        val_loss = 0
        with torch.no_grad():
            for X_batch, y_batch in val_loader:
                y_pred = model(X_batch)
                val_loss += criterion(y_pred, y_batch).item()
        val_loss /= len(val_loader)
        val_losses.append(val_loss)
        
        print(f"Epoch {epoch+1}/{epochs}")
        print(f"  Training Loss: {train_loss:.4f}  Validation Loss: {val_loss:.4f}")

        ax.clear()
        ax.plot(train_losses, label='Training Loss')
        ax.plot(val_losses, label='Validation Loss')
        ax.set_xlabel('Epoch')
        ax.set_ylabel('Loss')
        ax.legend()
        plt.draw()
        plt.pause(0.01)

        if val_loss < best_val_loss - threshold:
            best_val_loss = val_loss
            epochs_without_improvement = 0
            torch.save(model.state_dict(), 'best_lstm.pth')
            print("  Lowest validation loss achieved!")
        else:
            epochs_without_improvement += 1
            print(f"  Lowest validation loss achieved {epochs_without_improvement} epochs ago.")

        print("*" * 75)
        print("\n")

        if epochs_without_improvement >= patience:
            print(f"No improvement for {patience} epochs. Training stopped.")
            print("*" * 75)
            print("\n")
            break

    plt.ioff()
    plt.close()

    training_time = time.time() - start_time
    print(f"Training completed in {training_time:.2f} seconds")

def test_model(model, X_test_t, y_test_t, mean_y_test, std_y_test):
    model.load_state_dict(torch.load('best_lstm.pth'))
    model.eval()
    with torch.no_grad():
        y_test_pred = model(X_test_t).squeeze()
        test_predictions = y_test_pred.cpu().numpy()
        actuals = y_test_t.cpu().numpy()
    mse = np.mean((actuals - test_predictions)**2)
    print(f"\nThe MSE is {mse}.")

    actuals = actuals * std_y_test + mean_y_test
    test_predictions = test_predictions * std_y_test + mean_y_test

    fig, axs = plt.subplots(5, 1, figsize=(12, 24))
    result_titles = ['temperature_2m (°C)', 'precipitation (mm)', 'rain (mm)', 'cloudcover (%)', 'windspeed_10m (km/h)']
    
    for i, title in enumerate(result_titles):
        axs[i].plot(actuals[-5000:, i], label='Actual')
        axs[i].plot(test_predictions[-5000:, i], label='Predicted')
        axs[i].set_title(title)
        axs[i].legend()

    plt.tight_layout()
    plt.show()

def main():
    df = pd.read_csv('NYC_Weather_2016_2022.csv')
    df = df[['temperature_2m (°C)', 'precipitation (mm)', 'rain (mm)', 'cloudcover (%)', 'windspeed_10m (km/h)']]
    X, y = df_to_X_y(df, steps)

    X_train, y_train = X[:47616], y[:47616]
    X_val, y_val = X[47616:53568], y[47616:53568]
    X_test, y_test = X[53568:59510], y[53568:59510]
    
    print(y_test)

    X_train, y_train, mean_X_train, std_X_train, mean_y_train, std_y_train = normalize_data(X_train, y_train)
    X_val, y_val, mean_X_val, std_X_val, mean_y_val, std_y_val = normalize_data(X_val, y_val)
    X_test, y_test, mean_X_test, std_X_test, mean_y_test, std_y_test = normalize_data(X_test, y_test)
    
    np.save('./Data/xtest.npy', X_test)
    np.save('./Data/ytest.npy', y_test)

    X_train_t, y_train_t = to_tensor(X_train, y_train)
    X_val_t, y_val_t = to_tensor(X_val, y_val)
    X_test_t, y_test_t = to_tensor(X_test, y_test)
    
    input_dim = X_train.shape[2]
    output_dim = y_train.shape[1]
    model = LSTMModel(input_dim, units, output_dim, LSTM_layers, fc_layers)

    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    criterion = nn.MSELoss()

    train_loader = DataLoader(TensorDataset(X_train_t, y_train_t), batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(TensorDataset(X_val_t, y_val_t), batch_size=batch_size)

    train_model(model, train_loader, val_loader, optimizer, criterion, epochs, patience, threshold)
    test_model(model, X_test_t, y_test_t, mean_y_test, std_y_test)

    # Save model weights
    weights_dir = './Data/Weights'
    if os.path.exists(weights_dir):
        shutil.rmtree(weights_dir)
    os.makedirs(weights_dir, exist_ok=True)

    for name, param in model.state_dict().items():
        np.save(f'./Data/Weights/{name.replace(".", "_")}.npy', param.cpu().numpy())

    torch.onnx.export(model, X_test_t, "model.onnx")

if __name__ == "__main__":
    main()
